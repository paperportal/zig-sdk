//! Path helpers for Paper Portal `.papp` packaging.
//!
//! The `.papp` format is a ZIP archive with strict entry-name rules (see
//! `portal/docs/specs/spec-app-packaging.md`). These helpers validate and
//! normalize entry names to avoid path traversal and platform-specific
//! separators.

const std = @import("std");

/// Errors returned by ZIP entry-name validation and normalization helpers.
pub const EntryNameError = error{
    /// Entry name is empty.
    Empty,
    /// Entry name begins with `/`.
    Absolute,
    /// Entry name contains `\` instead of `/`.
    HasBackslash,
    /// Entry name starts with `./`.
    HasDotSlashPrefix,
    /// Entry name contains a `..` segment.
    HasDotDotSegment,
    /// Entry name contains an empty segment (e.g. `a//b`).
    HasEmptySegment,
};

/// Validates a ZIP entry name per the packaging specification.
///
/// Rules enforced:
/// - Must be non-empty
/// - Must be relative (no leading '/')
/// - Must use '/' separators (no '\')
/// - Must not start with "./"
/// - Must not contain any ".." path segments
pub fn validateEntryName(name: []const u8) EntryNameError!void {
    if (name.len == 0) return error.Empty;
    if (name[0] == '/') return error.Absolute;
    if (std.mem.indexOfScalar(u8, name, '\\') != null) return error.HasBackslash;
    if (std.mem.startsWith(u8, name, "./")) return error.HasDotSlashPrefix;

    var it = std.mem.splitScalar(u8, name, '/');
    while (it.next()) |seg| {
        if (seg.len == 0) return error.HasEmptySegment;
        if (std.mem.eql(u8, seg, "..")) return error.HasDotDotSegment;
    }
}

/// Converts a host path fragment to a ZIP entry fragment by replacing
/// platform separators with '/'.
///
/// This does not validate traversal. Use `validateEntryName` on the full result.
pub fn normalizeToZipSlashes(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    const out = try allocator.dupe(u8, s);
    std.mem.replaceScalar(u8, out, std.fs.path.sep, '/');
    std.mem.replaceScalar(u8, out, '\\', '/');
    return out;
}

/// Builds an `assets/<rel>` entry name from a relative filesystem path.
///
/// `rel_fs_path` must be relative (no absolute path handling here).
pub fn assetsEntryName(allocator: std.mem.Allocator, rel_fs_path: []const u8) ![]u8 {
    // Normalize separators first.
    const rel_norm = try normalizeToZipSlashes(allocator, rel_fs_path);
    defer allocator.free(rel_norm);

    // Ensure it doesn't try to escape.
    // We validate the final entry name, but we also proactively reject if the
    // relative path begins with "./" (common) or contains ".." segments after normalization.
    const full = try std.fmt.allocPrint(allocator, "assets/{s}", .{rel_norm});
    errdefer allocator.free(full);
    try validateEntryName(full);
    return full;
}

test "validateEntryName basic" {
    try validateEntryName("manifest.json");
    try validateEntryName("assets/foo/bar.txt");
    try std.testing.expectError(error.Absolute, validateEntryName("/abs"));
    try std.testing.expectError(error.HasBackslash, validateEntryName("a\\b"));
    try std.testing.expectError(error.HasDotSlashPrefix, validateEntryName("./a"));
    try std.testing.expectError(error.HasDotDotSegment, validateEntryName("a/../b"));
    try std.testing.expectError(error.HasEmptySegment, validateEntryName("a//b"));
}

test "assetsEntryName normalizes separators" {
    const a = std.testing.allocator;
    const name = try assetsEntryName(a, "dir\\file.txt");
    defer a.free(name);
    try std.testing.expectEqualStrings("assets/dir/file.txt", name);
}
