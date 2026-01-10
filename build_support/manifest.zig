//! Manifest construction and validation for Paper Portal `.papp` packages.
//!
//! This module builds the `manifest.json` file as specified in
//! `portal/docs/specs/spec-app-packaging.md`.
//!
//! It intentionally writes JSON with a stable key order for determinism.

const std = @import("std");

/// Errors raised while validating or rendering `manifest.json`.
pub const ManifestError = error{
    /// `id` is not a lower-case canonical UUID string.
    InvalidId,
    /// `version` does not match `#.#.#` (digits only).
    InvalidVersion,
    /// `name` is empty.
    EmptyName,
    /// `checksum` is not `sha256:<64 lower-hex>`.
    InvalidChecksum,
    /// Only one of `publisher_pubkey_b64` / `signature_b64` was provided.
    InvalidSigningFields,
};

/// Fully-populated manifest fields used to render `manifest.json`.
///
/// The packager computes and fills `checksum` and (optionally) signing fields.
pub const ManifestFields = struct {
    manifest_version: u32 = 1,
    sdk_version: u32 = 1,
    id: []const u8,
    name: []const u8,
    version: []const u8,
    checksum: []const u8,

    description: ?[]const u8 = null,
    author: ?[]const u8 = null,
    home_page: ?[]const u8 = null,
    copyright: ?[]const u8 = null,

    publisher_pubkey_b64: ?[]const u8 = null,
    signature_b64: ?[]const u8 = null,
};

/// Validates an app `id` (canonical lower-case UUID string).
pub fn validateId(id: []const u8) ManifestError!void {
    // Lower-case canonical UUID string: 8-4-4-4-12 hex.
    if (id.len != 36) return error.InvalidId;
    inline for (.{ 8, 13, 18, 23 }) |dash_idx| {
        if (id[dash_idx] != '-') return error.InvalidId;
    }
    for (id, 0..) |c, i| {
        if (i == 8 or i == 13 or i == 18 or i == 23) continue;
        const is_hex_lower = (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f');
        if (!is_hex_lower) return error.InvalidId;
    }
}

/// Validates an app `version` string in strict `#.#.#` format.
pub fn validateVersion(version: []const u8) ManifestError!void {
    // Format: digits '.' digits '.' digits (no prefixes/suffixes).
    if (version.len == 0) return error.InvalidVersion;
    var i: usize = 0;
    var parts: u2 = 0;
    while (true) {
        const start = i;
        while (i < version.len and std.ascii.isDigit(version[i])) : (i += 1) {}
        if (i == start) return error.InvalidVersion;
        parts += 1;
        if (parts == 3) break;
        if (i >= version.len or version[i] != '.') return error.InvalidVersion;
        i += 1;
    }
    if (i != version.len) return error.InvalidVersion;
}

/// Formats a SHA-256 digest as `sha256:<lower-hex>`.
pub fn formatChecksumSha256Hex(allocator: std.mem.Allocator, digest: [32]u8) ![]u8 {
    // sha256:<64 lower-hex>
    const hex = std.fmt.bytesToHex(digest, .lower);
    return std.fmt.allocPrint(allocator, "sha256:{s}", .{hex[0..]});
}

/// Validates the manifest fields against the packaging spec.
pub fn validate(fields: ManifestFields) ManifestError!void {
    try validateId(fields.id);
    if (fields.name.len == 0) return error.EmptyName;
    try validateVersion(fields.version);
    if (!std.mem.startsWith(u8, fields.checksum, "sha256:") or fields.checksum.len != 7 + 64) return error.InvalidChecksum;
    if ((fields.publisher_pubkey_b64 == null) != (fields.signature_b64 == null)) {
        // must both be present or both absent
        return error.InvalidSigningFields;
    }
}

/// Writes `manifest.json` to `writer` as UTF-8 JSON with stable key order.
/// Writes a spec-compliant `manifest.json` object (UTF-8 JSON).
///
/// The JSON keys are written in a stable order for deterministic output.
pub fn writeJson(fields: ManifestFields, writer: *std.Io.Writer) !void {
    try validate(fields);

    const enc = std.json.Stringify;
    const opts: enc.Options = .{ .escape_unicode = false };

    // Required keys first.
    try writer.writeAll("{");
    try writer.writeAll("\"manifest_version\":");
    try writer.print("{d}", .{fields.manifest_version});
    try writer.writeAll(",\"sdk_version\":");
    try writer.print("{d}", .{fields.sdk_version});

    try writer.writeAll(",\"id\":");
    try enc.encodeJsonString(fields.id, opts, writer);
    try writer.writeAll(",\"name\":");
    try enc.encodeJsonString(fields.name, opts, writer);
    try writer.writeAll(",\"checksum\":");
    try enc.encodeJsonString(fields.checksum, opts, writer);
    try writer.writeAll(",\"version\":");
    try enc.encodeJsonString(fields.version, opts, writer);

    // Optional metadata.
    if (fields.description) |v| {
        try writer.writeAll(",\"description\":");
        try enc.encodeJsonString(v, opts, writer);
    }
    if (fields.author) |v| {
        try writer.writeAll(",\"author\":");
        try enc.encodeJsonString(v, opts, writer);
    }
    if (fields.home_page) |v| {
        try writer.writeAll(",\"home_page\":");
        try enc.encodeJsonString(v, opts, writer);
    }
    if (fields.copyright) |v| {
        try writer.writeAll(",\"copyright\":");
        try enc.encodeJsonString(v, opts, writer);
    }

    // Optional signing (must include both).
    if (fields.publisher_pubkey_b64) |pk| {
        const sig = fields.signature_b64.?;
        try writer.writeAll(",\"publisher_pubkey\":");
        try enc.encodeJsonString(pk, opts, writer);
        try writer.writeAll(",\"signature\":");
        try enc.encodeJsonString(sig, opts, writer);
    }

    try writer.writeAll("}");
}

test "validateId canonical lower uuid" {
    try validateId("3fa85f64-5717-4562-b3fc-2c963f66afa6");
    try std.testing.expectError(error.InvalidId, validateId("3FA85F64-5717-4562-b3fc-2c963f66afa6"));
    try std.testing.expectError(error.InvalidId, validateId("not-a-uuid"));
}

test "validateVersion strict semver-ish" {
    try validateVersion("0.0.0");
    try validateVersion("1.2.345");
    try std.testing.expectError(error.InvalidVersion, validateVersion("1.2"));
    try std.testing.expectError(error.InvalidVersion, validateVersion("v1.2.3"));
    try std.testing.expectError(error.InvalidVersion, validateVersion("1.2.3-beta"));
}
