//! Build-step implementation for packaging `.papp` files.
//!
//! This file is intended to be imported from `zig-sdk/build.zig` and used by
//! consumer `build.zig` scripts via `@import("paper_portal_sdk")`.

const std = @import("std");

const manifest = @import("manifest.zig");
const signing = @import("signing.zig");
const paths = @import("paths.zig");
const zip_writer = @import("zip_writer.zig");

/// Supported ZIP compression methods for `.papp` creation.
pub const ZipCompression = zip_writer.ZipCompression;

/// Per-entry compression policy for `.papp` creation.
pub const CompressionOptions = struct {
    wasm: ZipCompression = .deflate,
    manifest: ZipCompression = .store,
    icon: ZipCompression = .store,
    assets: ZipCompression = .store,
};

/// Inputs used to populate `manifest.json` (the packager computes `checksum`).
pub const ManifestOptions = struct {
    manifest_version: u32 = 1,
    sdk_version: u32 = 1,
    id: []const u8,
    name: []const u8,
    version: []const u8,

    description: ?[]const u8 = null,
    author: ?[]const u8 = null,
    home_page: ?[]const u8 = null,
    copyright: ?[]const u8 = null,
};

/// Optional Ed25519 signing configuration for `.papp` packages.
pub const SigningOptions = struct {
    seed_b64: ?[]const u8 = null,
    seed_option_name: []const u8 = "paperportal-publisher-seed-b64",
    seed_env_var: []const u8 = "PAPERPORTAL_PUBLISHER_SEED_B64",
    deterministic: bool = true,
};

/// Options for generating a Paper Portal `.papp` package.
pub const PappOptions = struct {
    step_name: []const u8 = "package",
    step_description: []const u8 = "Build a Paper Portal .papp package",

    manifest: ManifestOptions,
    icon_png: ?std.Build.LazyPath = null,
    assets_dir: ?std.Build.LazyPath = null,
    output_basename: ?[]const u8 = null,
    compression: CompressionOptions = .{},
    signing: ?SigningOptions = null,
};

/// Result of configuring a `.papp` packaging step.
pub const PortalPackage = struct {
    step: *std.Build.Step,
    generated_papp: *const std.Build.GeneratedFile,

    /// Returns a `LazyPath` representing the generated `.papp` file.
    pub fn getEmittedPapp(self: *PortalPackage) std.Build.LazyPath {
        return .{ .generated = .{ .file = self.generated_papp } };
    }
};

/// Adds a build step that generates a `.papp` package from a `.wasm` file.
///
/// The package is installed to `zig-out/<name>-<version>.papp` by default.
pub fn addPortalPackage(b: *std.Build, wasm_file: std.Build.LazyPath, opts: PappOptions) *PortalPackage {
    const pkg_step = PortalPackageStep.create(b, wasm_file, opts);

    const basename = deriveBasename(b, opts);
    const install = b.addInstallFile(pkg_step.getEmittedPapp(), basename);

    const top = b.step(opts.step_name, opts.step_description);
    top.dependOn(&install.step);

    // Return an object exposing the generated output too.
    const pkg = b.allocator.create(PortalPackage) catch @panic("OOM");
    pkg.* = .{
        .step = top,
        .generated_papp = &pkg_step.generated_papp,
    };
    return pkg;
}

/// Adds a build step that generates a `.papp` package from a wasm artifact.
pub fn addWasmPortalPackage(b: *std.Build, wasm_artifact: *std.Build.Step.Compile, opts: PappOptions) *PortalPackage {
    return addPortalPackage(b, wasm_artifact.getEmittedBin(), opts);
}

const PortalPackageStep = struct {
    step: std.Build.Step,
    wasm_file: std.Build.LazyPath,
    opts: PappOptions,
    generated_papp: std.Build.GeneratedFile,

    /// Creates the underlying custom build step.
    pub fn create(b: *std.Build, wasm_file: std.Build.LazyPath, opts: PappOptions) *PortalPackageStep {
        const self = b.allocator.create(PortalPackageStep) catch @panic("OOM");
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = b.fmt("Package .papp", .{}),
                .owner = b,
                .makeFn = make,
            }),
            .wasm_file = wasm_file,
            .opts = opts,
            .generated_papp = .{ .step = &self.step },
        };
        wasm_file.addStepDependencies(&self.step);
        if (opts.icon_png) |p| p.addStepDependencies(&self.step);
        if (opts.assets_dir) |p| p.addStepDependencies(&self.step);
        return self;
    }

    /// Returns the generated `.papp` output as a `LazyPath`.
    pub fn getEmittedPapp(self: *PortalPackageStep) std.Build.LazyPath {
        return .{ .generated = .{ .file = &self.generated_papp } };
    }

    /// Build runner entrypoint for producing the `.papp` file.
    fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
        const self: *PortalPackageStep = @fieldParentPtr("step", step);
        const b = step.owner;
        const io = b.graph.io;
        const gpa = options.gpa;

        // Resolve paths.
        const wasm_path = self.wasm_file.getPath2(b, step);

        // Compute SHA-256 of wasm.
        var wasm_file = openFileAny(io, wasm_path) catch |err| {
            return step.fail("failed to open app.wasm at {s}: {s}", .{ wasm_path, @errorName(err) });
        };
        defer wasm_file.close(io);

        const wasm_stat = wasm_file.stat(io) catch |err| {
            return step.fail("failed to stat app.wasm at {s}: {s}", .{ wasm_path, @errorName(err) });
        };
        if (wasm_stat.kind != .file) return step.fail("app.wasm is not a regular file: {s}", .{wasm_path});

        var sha = std.crypto.hash.sha2.Sha256.init(.{});
        var crc_buf: [64 * 1024]u8 = undefined;
        var remaining: u64 = wasm_stat.size;
        while (remaining != 0) {
            const want: usize = @intCast(@min(@as(u64, crc_buf.len), remaining));
            const n = wasm_file.readStreaming(io, &.{crc_buf[0..want]}) catch |err| {
                return step.fail("failed to read app.wasm at {s}: {s}", .{ wasm_path, @errorName(err) });
            };
            if (n == 0) break;
            sha.update(crc_buf[0..n]);
            remaining -= n;
        }
        if (remaining != 0) return step.fail("short read while hashing wasm: {s}", .{wasm_path});

        var digest: [32]u8 = undefined;
        sha.final(&digest);
        const checksum = try manifest.formatChecksumSha256Hex(gpa, digest);
        defer gpa.free(checksum);

        // Prepare optional signing.
        var pubkey_b64: ?[]u8 = null;
        var sig_b64: ?[]u8 = null;
        defer {
            if (pubkey_b64) |s| gpa.free(s);
            if (sig_b64) |s| gpa.free(s);
        }

        if (self.opts.signing) |sopts| {
            const seed_b64 = resolveSeed(b, sopts) orelse
                return step.fail("missing signing seed (set -D{s}=... or {s})", .{ sopts.seed_option_name, sopts.seed_env_var });
            const seed32 = signing.decodeSeed(seed_b64) catch |err| {
                return step.fail("invalid signing seed: {s}", .{@errorName(err)});
            };
            const sig_res = signing.signDeterministic(gpa, seed32, self.opts.manifest.id, checksum) catch |err| {
                return step.fail("failed to sign manifest: {s}", .{@errorName(err)});
            };
            pubkey_b64 = sig_res.publisher_pubkey_b64;
            sig_b64 = sig_res.signature_b64;
        }

        // Build manifest.json bytes.
        var manifest_out: std.Io.Writer.Allocating = .init(gpa);
        defer manifest_out.deinit();
        const mf: manifest.ManifestFields = .{
            .manifest_version = self.opts.manifest.manifest_version,
            .sdk_version = self.opts.manifest.sdk_version,
            .id = self.opts.manifest.id,
            .name = self.opts.manifest.name,
            .version = self.opts.manifest.version,
            .checksum = checksum,
            .description = self.opts.manifest.description,
            .author = self.opts.manifest.author,
            .home_page = self.opts.manifest.home_page,
            .copyright = self.opts.manifest.copyright,
            .publisher_pubkey_b64 = if (pubkey_b64) |s| s else null,
            .signature_b64 = if (sig_b64) |s| s else null,
        };
        manifest.writeJson(mf, &manifest_out.writer) catch |err| {
            return step.fail("invalid manifest options: {s}", .{@errorName(err)});
        };
        const manifest_bytes = manifest_out.writer.buffered();

        // Determine output path under cache_root.
        const basename = deriveBasename(b, self.opts);
        const checksum_hex = checksum[7..];
        // `GeneratedFile.path` must remain valid after `make()` returns, so we
        // allocate `out_path` with the build allocator and do not free it.
        const out_path = b.cache_root.join(b.allocator, &.{ "papp", self.opts.manifest.id, checksum_hex, basename }) catch @panic("OOM");
        const tmp_dir = b.cache_root.join(gpa, &.{ "papp", self.opts.manifest.id, checksum_hex, "tmp" }) catch @panic("OOM");
        defer gpa.free(tmp_dir);

        if (std.fs.path.dirname(out_path)) |d| {
            try std.Io.Dir.cwd().createDirPath(io, d);
        }
        try std.Io.Dir.cwd().createDirPath(io, tmp_dir);

        // Create output file (truncate).
        var out = createFileAny(io, out_path) catch |err| {
            return step.fail("failed to create output .papp at {s}: {s}", .{ out_path, @errorName(err) });
        };
        defer out.close(io);

        var out_writer_buf: [8 * 1024]u8 = undefined;
        var out_writer = out.writer(io, out_writer_buf[0..]);
        var zw = zip_writer.ZipWriter.init(gpa, &out_writer.interface);
        defer zw.deinit();

        // Required entries.
        try paths.validateEntryName("manifest.json");
        zw.addBytes("manifest.json", manifest_bytes, self.opts.compression.manifest) catch |err| {
            return step.fail("failed to add manifest.json to zip: {s}", .{@errorName(err)});
        };

        try paths.validateEntryName("app.wasm");
        zw.addFileFromDisk(io, "app.wasm", wasm_path, self.opts.compression.wasm, tmp_dir) catch |err| {
            return step.fail("failed to add app.wasm to zip: {s}", .{@errorName(err)});
        };

        // Optional icon.
        if (self.opts.icon_png) |icon_lp| {
            const icon_path = icon_lp.getPath2(b, step);
            try paths.validateEntryName("icon.png");
            zw.addFileFromDisk(io, "icon.png", icon_path, self.opts.compression.icon, tmp_dir) catch |err| {
                return step.fail("failed to add icon.png to zip: {s}", .{@errorName(err)});
            };
        }

        // Optional assets.
        if (self.opts.assets_dir) |assets_lp| {
            const assets_path = assets_lp.getPath2(b, step);
            addAssetsDir(step, gpa, io, &zw, assets_path, self.opts.compression.assets, tmp_dir) catch |err| {
                return step.fail("failed to add assets dir {s}: {s}", .{ assets_path, @errorName(err) });
            };
        }

        zw.finish() catch |err| return step.fail("failed to finalize zip: {s}", .{@errorName(err)});
        out_writer.interface.flush() catch |err| return step.fail("failed to flush output .papp: {s}", .{@errorName(err)});
        out.sync(io) catch |err| return step.fail("failed to sync output .papp: {s}", .{@errorName(err)});

        self.generated_papp.path = out_path;
    }
};

/// Resolves the signing seed string using precedence:
/// `SigningOptions.seed_b64` > `-D<seed_option_name>` > `<seed_env_var>`.
fn resolveSeed(b: *std.Build, opts: SigningOptions) ?[]const u8 {
    if (opts.seed_b64) |v| return v;
    if (b.option([]const u8, opts.seed_option_name, "Paper Portal publisher seed (Base64; 32 bytes decoded)")) |v| return v;
    return b.graph.environ_map.get(opts.seed_env_var);
}

/// Opens a file for reading from either an absolute path or CWD-relative path.
fn openFileAny(io: std.Io, path_any: []const u8) std.Io.File.OpenError!std.Io.File {
    return if (std.fs.path.isAbsolute(path_any))
        std.Io.Dir.openFileAbsolute(io, path_any, .{ .mode = .read_only, .allow_directory = false })
    else
        std.Io.Dir.cwd().openFile(io, path_any, .{ .mode = .read_only, .allow_directory = false });
}

/// Creates/truncates a file for writing at either an absolute path or CWD-relative path.
fn createFileAny(io: std.Io, path_any: []const u8) std.Io.File.OpenError!std.Io.File {
    return if (std.fs.path.isAbsolute(path_any))
        std.Io.Dir.createFileAbsolute(io, path_any, .{ .truncate = true, .read = false })
    else
        std.Io.Dir.cwd().createFile(io, path_any, .{ .truncate = true, .read = false });
}

/// Determines the installed `.papp` output basename (including `.papp` extension).
fn deriveBasename(b: *std.Build, opts: PappOptions) []const u8 {
    if (opts.output_basename) |s| return ensurePappSuffix(b, s);
    const safe_name = sanitizeForFilename(b, opts.manifest.name);
    const base = b.fmt("{s}-{s}.papp", .{ safe_name, opts.manifest.version });
    return base;
}

/// Ensures `s` ends with `.papp`.
fn ensurePappSuffix(b: *std.Build, s: []const u8) []const u8 {
    if (std.mem.endsWith(u8, s, ".papp")) return s;
    return b.fmt("{s}.papp", .{s});
}

/// Sanitizes an app name into a filesystem-friendly filename component.
fn sanitizeForFilename(b: *std.Build, s: []const u8) []const u8 {
    // Keep ASCII alnum, '.', '_', '-', replace others with '-'.
    var buf = std.array_list.Managed(u8).init(b.allocator);
    defer buf.deinit();
    for (s) |c| {
        const ok = std.ascii.isAlphanumeric(c) or c == '.' or c == '_' or c == '-';
        buf.append(if (ok) c else '-') catch @panic("OOM");
    }
    // Collapse empty to "app"
    if (buf.items.len == 0) buf.appendSlice("app") catch @panic("OOM");
    return b.dupe(buf.items);
}

/// Recursively adds files under `assets_root` to the package as `assets/**`.
fn addAssetsDir(
    step: *std.Build.Step,
    allocator: std.mem.Allocator,
    io: std.Io,
    zw: *zip_writer.ZipWriter,
    assets_root: []const u8,
    method: ZipCompression,
    tmp_dir_path: []const u8,
) !void {
    // Ensure directory exists.
    var dir = if (std.fs.path.isAbsolute(assets_root))
        try std.Io.Dir.openDirAbsolute(io, assets_root, .{ .iterate = true })
    else
        try std.Io.Dir.cwd().openDir(io, assets_root, .{ .iterate = true });
    defer dir.close(io);

    // Walk recursively.
    var stack = std.array_list.Managed([]const u8).init(allocator);
    defer {
        for (stack.items) |p| allocator.free(p);
        stack.deinit();
    }
    try stack.append(try allocator.dupe(u8, ""));

    while (stack.pop()) |rel_dir| {
        defer allocator.free(rel_dir);

        const scan_path = if (rel_dir.len == 0)
            assets_root
        else
            try std.fs.path.join(allocator, &.{ assets_root, rel_dir });
        defer if (rel_dir.len != 0) allocator.free(scan_path);

        var sub = if (std.fs.path.isAbsolute(scan_path))
            try std.Io.Dir.openDirAbsolute(io, scan_path, .{ .iterate = true })
        else
            try std.Io.Dir.cwd().openDir(io, scan_path, .{ .iterate = true });
        defer sub.close(io);

        var it = sub.iterate();
        while (try it.next(io)) |ent| {
            if (ent.kind == .directory) {
                // Skip "." and ".." (shouldn't appear, but defensive).
                if (std.mem.eql(u8, ent.name, ".") or std.mem.eql(u8, ent.name, "..")) continue;
                const child = if (rel_dir.len == 0)
                    try allocator.dupe(u8, ent.name)
                else
                    try std.fmt.allocPrint(allocator, "{s}{c}{s}", .{ rel_dir, std.fs.path.sep, ent.name });
                try stack.append(child);
                continue;
            }
            if (ent.kind != .file) continue;

            const rel_file = if (rel_dir.len == 0)
                try allocator.dupe(u8, ent.name)
            else
                try std.fmt.allocPrint(allocator, "{s}{c}{s}", .{ rel_dir, std.fs.path.sep, ent.name });
            defer allocator.free(rel_file);

            const entry_name = try paths.assetsEntryName(allocator, rel_file);
            defer allocator.free(entry_name);

            const file_path = try std.fs.path.join(allocator, &.{ assets_root, rel_file });
            defer allocator.free(file_path);

            zw.addFileFromDisk(io, entry_name, file_path, method, tmp_dir_path) catch |err| {
                return step.fail("failed to add asset {s}: {s}", .{ rel_file, @errorName(err) });
            };
        }
    }
}
