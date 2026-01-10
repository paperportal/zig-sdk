//! Optional `.papp` signing helpers.
//!
//! Implements Ed25519 signing as specified in `portal/docs/specs/spec-app-packaging.md`.
//! The signed message is:
//!   `paperportal.papp.v1\n` + `<id>` + `\n` + `<checksum>` + `\n`

const std = @import("std");

/// Errors that can occur while building `.papp` signature fields.
pub const SigningError = error{
    /// No seed was provided via options/CLI/env.
    MissingSeed,
    /// The seed Base64 string is invalid.
    InvalidSeedBase64,
    /// The decoded seed is not exactly 32 bytes.
    WrongSeedLength,
    /// Ed25519 key derivation failed (e.g. identity element).
    KeyDerivationFailed,
    /// Signing failed.
    SignFailed,
};

/// Base64-encoded Ed25519 signing results to embed into `manifest.json`.
pub const SignatureResult = struct {
    publisher_pubkey_b64: []u8,
    signature_b64: []u8,
};

/// Builds the exact message bytes signed by `.papp` signature v1.
pub fn message(allocator: std.mem.Allocator, id: []const u8, checksum: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "paperportal.papp.v1\n{s}\n{s}\n", .{ id, checksum });
}

/// Decodes a Base64-encoded 32-byte Ed25519 seed.
pub fn decodeSeed(seed_b64: []const u8) SigningError![32]u8 {
    const dec = std.base64.standard.Decoder;
    const want = dec.calcSizeForSlice(seed_b64) catch return error.InvalidSeedBase64;
    if (want != 32) return error.WrongSeedLength;
    var out: [32]u8 = undefined;
    dec.decode(out[0..], seed_b64) catch return error.InvalidSeedBase64;
    return out;
}

/// Computes `publisher_pubkey` and `signature` for the given manifest id/checksum.
///
/// The signature is deterministic (noise = null) to make builds reproducible.
pub fn signDeterministic(
    allocator: std.mem.Allocator,
    seed32: [32]u8,
    id: []const u8,
    checksum: []const u8,
) SigningError!SignatureResult {
    const Ed25519 = std.crypto.sign.Ed25519;

    const kp = Ed25519.KeyPair.generateDeterministic(seed32) catch return error.KeyDerivationFailed;
    const msg = message(allocator, id, checksum) catch return error.SignFailed;
    defer allocator.free(msg);

    const sig = kp.sign(msg, null) catch return error.SignFailed;

    const pk_bytes = kp.public_key.toBytes();
    const sig_bytes = sig.toBytes();

    const enc = std.base64.standard.Encoder;
    const pk_len = enc.calcSize(pk_bytes.len);
    const sig_len = enc.calcSize(sig_bytes.len);

    const pk_b64 = allocator.alloc(u8, pk_len) catch return error.SignFailed;
    errdefer allocator.free(pk_b64);
    const sig_b64 = allocator.alloc(u8, sig_len) catch return error.SignFailed;
    errdefer allocator.free(sig_b64);

    _ = enc.encode(pk_b64, &pk_bytes);
    _ = enc.encode(sig_b64, &sig_bytes);

    return .{
        .publisher_pubkey_b64 = pk_b64,
        .signature_b64 = sig_b64,
    };
}

test "decodeSeed length enforcement" {
    const enc = std.base64.standard.Encoder;
    var seed: [32]u8 = .{0} ** 32;
    seed[0] = 1;
    var buf: [64]u8 = undefined;
    const b64 = enc.encode(&buf, &seed);
    _ = try decodeSeed(b64);
}

test "signDeterministic produces verifiable signature" {
    const a = std.testing.allocator;
    const seed: [32]u8 = .{1} ** 32;
    const id = "3fa85f64-5717-4562-b3fc-2c963f66afa6";
    const checksum = "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    const res = try signDeterministic(a, seed, id, checksum);
    defer a.free(res.publisher_pubkey_b64);
    defer a.free(res.signature_b64);

    // Decode and verify.
    const Ed25519 = std.crypto.sign.Ed25519;
    var pk_bytes: [Ed25519.PublicKey.encoded_length]u8 = undefined;
    var sig_bytes: [Ed25519.Signature.encoded_length]u8 = undefined;
    const dec = std.base64.standard.Decoder;
    try dec.decode(pk_bytes[0..], res.publisher_pubkey_b64);
    try dec.decode(sig_bytes[0..], res.signature_b64);

    const pk = Ed25519.PublicKey.fromBytes(pk_bytes) catch return error.KeyDerivationFailed;
    const sig = Ed25519.Signature.fromBytes(sig_bytes);

    const msg = try message(a, id, checksum);
    defer a.free(msg);
    try sig.verifyStrict(msg, pk);
}
