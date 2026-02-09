const std = @import("std");
const papp = @import("build_support/papp.zig");

/// Zig Paper Portal SDK package build script.
///
/// This package exports:
/// - A Zig module named `paper_portal_sdk` (see `sdk.zig`), and
/// - Convenience helpers for adding an `upload` build step to your project.
/// - Convenience helpers for building `.papp` packages (see `addWasmPortalPackage`).
///
/// The `upload` step POSTs a `.wasm` file to a Paper Portal device dev server.
/// It is implemented in pure Zig (no external tools such as `curl`).
///
/// Options for the build helper step added by `addWasmUpload`/`addUploadStep`.
///
/// Minimal usage from a consumer `build.zig`:
///
/// ```zig
/// const pp_sdk = @import("paper_portal_sdk");
/// _ = pp_sdk.addWasmUpload(b, exe, .{});
/// ```
///
/// Host/port selection precedence:
/// 1) CLI (`-Dpaperportal-host=...`, `-Dpaperportal-port=...`)
/// 2) Environment (`PAPERPORTAL_HOST`, `PAPERPORTAL_PORT`)
/// 3) Defaults (`portal.local:80`)
pub const UploadOptions = struct {
    /// The top-level build step name. Users will run `zig build <step_name>`.
    step_name: []const u8 = "upload",
    step_description: []const u8 = "Upload the generated wasm to the Paper Portal dev server",

    /// HTTP endpoint path on the Paper Portal device.
    endpoint_path: []const u8 = "/api/run",

    /// Used when neither the CLI option nor the env var is set.
    default_host: []const u8 = "portal.local",
    /// Used when neither the CLI option nor the env var is set.
    default_port: u16 = 80,

    /// CLI overrides (e.g. `zig build upload -Dpaperportal-host=portal.local`).
    host_option_name: []const u8 = "paperportal-host",
    port_option_name: []const u8 = "paperportal-port",

    /// Env var overrides (used when no CLI override is set).
    host_env_var: []const u8 = "PAPERPORTAL_HOST",
    port_env_var: []const u8 = "PAPERPORTAL_PORT",

    /// Maximum time to wait for the server to begin responding (headers). Set to `0` to disable the timeout.
    response_timeout_ms: u32 = 10_000,
};

/// ZIP compression options supported by the `.papp` packager.
pub const ZipCompression = papp.ZipCompression;

/// `.papp` ZIP entry compression selection.
pub const CompressionOptions = papp.CompressionOptions;

/// `manifest.json` inputs (the packager computes `checksum` automatically).
pub const ManifestOptions = papp.ManifestOptions;

/// Optional Ed25519 signing inputs for `.papp` packages.
pub const SigningOptions = papp.SigningOptions;

/// Options for building a Paper Portal `.papp` package.
///
/// Minimal usage from a consumer `build.zig`:
///
/// ```zig
/// const pp_sdk = @import("paper_portal_sdk");
/// _ = pp_sdk.addPortalPackage(b, exe, .{
///     .manifest = .{
///         .id = "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///         .name = "Notes",
///         .version = "1.0.0",
///     },
/// });
/// ```
pub const PappOptions = papp.PappOptions;

/// Result of configuring a `.papp` packaging step.
pub const PortalPackage = papp.PortalPackage;

pub const PortalAppOptions = struct {
    local_sdk_path: ?[]const u8 = null,

    /// Exports to include in the final `.wasm`.
    ///
    /// Example:
    /// `&.{ "pp_contract_version", "pp_init", "pp_shutdown", "pp_alloc", "pp_free", "pp_on_gesture" }`
    export_symbol_names: []const []const u8,

    /// Default target for Paper Portal apps. Users may override via CLI target options.
    os_tag: std.Target.Os.Tag = .freestanding,

    /// WASM optimization mode (Paper Portal apps generally prefer `.ReleaseSmall`).
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,

    /// Root source file for the app.
    root_source_file: []const u8 = "src/main.zig",

    /// Output artifact name.
    exe_name: []const u8 = "main",

    /// Configure the wasm linear memory. Values are bytes.
    stack_size: u64 = 32 * 1024,
    initial_memory: u64 = 512 * 1024,
    max_memory: u64 = 1024 * 1024,

    /// Install this artifact to `zig-out/` (via `b.installArtifact`).
    install_artifact: bool = true,

    /// Adds an `upload` build step (see `UploadOptions`).
    add_upload_step: bool = true,
    upload: UploadOptions = .{},

    /// Zig dependency name used to locate the SDK `sdk.zig` module.
    sdk_dependency_name: []const u8 = "paper_portal_sdk",
};

pub const PortalApp = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    root_mod: *std.Build.Module,
    exe: *std.Build.Step.Compile,
    upload_step: ?*std.Build.Step,
};

/// Configures a Paper Portal Zig/WASM app with the project-default settings:
/// target, root module, exports, SDK import, upload step, memory settings, and install steps.
pub fn addPortalApp(b: *std.Build, opts: PortalAppOptions) PortalApp {
    const target = b.standardTargetOptions(.{
        .default_target = .{ .cpu_arch = .wasm32, .os_tag = opts.os_tag },
    });

    const root_mod = b.createModule(.{
        .root_source_file = b.path(opts.root_source_file),
        .target = target,
        .optimize = opts.optimize,
        .strip = true,
    });
    root_mod.export_symbol_names = opts.export_symbol_names;

    const exe = b.addExecutable(.{
        .name = opts.exe_name,
        .root_module = root_mod,
    });

    if (opts.os_tag == .freestanding) {
        exe.entry = .disabled;
    }

    const upload_step: ?*std.Build.Step = if (opts.add_upload_step)
        addWasmUpload(b, exe, opts.upload)
    else
        null;

    var sdk_dep = b.dependency("paper_portal_sdk", .{});
    if (opts.local_sdk_path) |path| {
        if (dirExists(b, path)) {
            const local_name = b.fmt("{s}_local", .{opts.sdk_dependency_name});
            sdk_dep = (b.lazyDependency(local_name, .{}) orelse @panic("local sdk dependency missing"));
        }
    }

    const sdk = b.createModule(.{
        .root_source_file = sdk_dep.path("sdk.zig"),
        .target = target,
        .optimize = opts.optimize,
    });
    exe.root_module.addImport("paper_portal_sdk", sdk);

    exe.stack_size = opts.stack_size;
    exe.initial_memory = opts.initial_memory;
    exe.max_memory = opts.max_memory;

    if (opts.install_artifact) {
        b.installArtifact(exe);
    }

    return .{
        .target = target,
        .optimize = opts.optimize,
        .root_mod = root_mod,
        .exe = exe,
        .upload_step = upload_step,
    };
}

/// Adds an upload step that depends on the output of `wasm_artifact`.
///
/// This is a convenience wrapper around `addUploadStep` that uses
/// `wasm_artifact.getEmittedBin()` as the file to upload.
pub fn addWasmUpload(b: *std.Build, wasm_artifact: *std.Build.Step.Compile, opts: UploadOptions) *std.Build.Step {
    return addUploadStep(b, wasm_artifact.getEmittedBin(), opts);
}

/// Adds a packaging step that creates a Paper Portal `.papp` file.
///
/// The resulting `.papp` is installed to `zig-out/` under the install prefix.
pub fn addPortalPackage(b: *std.Build, wasm_artifact: *std.Build.Step.Compile, opts: PappOptions) *PortalPackage {
    return papp.addPortalPackage(b, wasm_artifact, opts);
}

/// Adds an upload step that POSTs `wasm_file` to a Paper Portal device dev server.
///
/// The request is:
/// - Method: `POST`
/// - URL: `http://<host>:<port><endpoint_path>` (always HTTP)
/// - Content-Type: `application/wasm`
///
/// On non-2xx responses, the step fails.
pub fn addUploadStep(b: *std.Build, wasm_file: std.Build.LazyPath, opts: UploadOptions) *std.Build.Step {
    const upload_step = b.step(opts.step_name, opts.step_description);

    const resolved = resolveHostPort(b, opts);
    switch (resolved) {
        .err => |msg| {
            const fail = b.addFail(msg);
            upload_step.dependOn(&fail.step);
            return upload_step;
        },
        .ok => |hp| {
            const url = formatUrl(b, hp.host, hp.port, opts.endpoint_path);
            const uploader = UploadWasmStep.create(b, wasm_file, url, opts.response_timeout_ms);
            upload_step.dependOn(&uploader.step);
            return upload_step;
        },
    }
}

/// Build script entrypoint for the `paper_portal_sdk` package.
pub fn build(b: *std.Build) void {
    _ = b.addModule("paper_portal_sdk", .{
        .root_source_file = b.path("sdk.zig"),
    });
}

const UploadWasmStep = struct {
    step: std.Build.Step,
    wasm_file: std.Build.LazyPath,
    url: []const u8,
    response_timeout_ms: u32,

    /// Creates a custom build step that uploads `wasm_file` to `url`.
    pub fn create(b: *std.Build, wasm_file: std.Build.LazyPath, url: []const u8, response_timeout_ms: u32) *UploadWasmStep {
        const self = b.allocator.create(UploadWasmStep) catch @panic("OOM");
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = b.fmt("Upload to Paper Portal dev server", .{}),
                .owner = b,
                .makeFn = make,
            }),
            .wasm_file = wasm_file,
            .url = url,
            .response_timeout_ms = response_timeout_ms,
        };
        wasm_file.addStepDependencies(&self.step);
        return self;
    }

    fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
        const self: *UploadWasmStep = @fieldParentPtr("step", step);
        const b = step.owner;
        const graph = b.graph;
        const io = graph.io;

        const wasm_path = self.wasm_file.getPath2(b, step);
        var file = (if (std.fs.path.isAbsolute(wasm_path))
            std.Io.Dir.openFileAbsolute(io, wasm_path, .{ .mode = .read_only, .allow_directory = false })
        else
            std.Io.Dir.cwd().openFile(io, wasm_path, .{ .mode = .read_only, .allow_directory = false })) catch |err| {
            return step.fail("failed to open {s}: {t}", .{ wasm_path, err });
        };
        defer file.close(io);

        const st = file.stat(io) catch |err| {
            return step.fail("failed to stat {s}: {t}", .{ wasm_path, err });
        };
        if (st.kind != .file) {
            return step.fail("not a regular file: {s}", .{wasm_path});
        }

        const uri = std.Uri.parse(self.url) catch |err| {
            return step.fail("invalid upload url {s}: {any}", .{ self.url, err });
        };

        var client: std.http.Client = .{ .allocator = options.gpa, .io = io };
        errdefer client.deinit();

        var req = client.request(.POST, uri, .{
            .keep_alive = false,
            .headers = .{
                .content_type = .{ .override = "application/wasm" },
                .user_agent = .{ .override = "paperportal-zig-uploader" },
            },
        }) catch |err| {
            return step.fail("failed to create request to {s}: {t}", .{ self.url, err });
        };
        errdefer req.deinit();

        req.transfer_encoding = .{ .content_length = st.size };

        var send_buf: [16 * 1024]u8 = undefined;
        var body_writer = req.sendBody(send_buf[0..]) catch |err| {
            return step.fail("failed to start request body: {t}", .{err});
        };

        var copy_buf: [64 * 1024]u8 = undefined;
        var uploaded: u64 = 0;
        while (uploaded < st.size) {
            const remaining = st.size - uploaded;
            const want: usize = @intCast(@min(@as(u64, copy_buf.len), remaining));
            const n = file.readStreaming(io, &.{copy_buf[0..want]}) catch |err| {
                return step.fail("failed to read {s}: {t}", .{ wasm_path, err });
            };
            if (n == 0) break;

            body_writer.writer.writeAll(copy_buf[0..n]) catch |err| {
                return step.fail("failed to send request body: {t}", .{err});
            };

            uploaded += n;
        }

        if (uploaded != st.size) {
            return step.fail("short read for {s}: read {d} of {d} bytes", .{ wasm_path, uploaded, st.size });
        }

        body_writer.end() catch |err| {
            return step.fail("failed to finalize request body: {t}", .{err});
        };

        if (req.connection) |conn| if (self.response_timeout_ms != 0) {
            var fds: [1]std.posix.pollfd = .{.{
                .fd = conn.stream_reader.stream.socket.handle,
                .events = std.posix.POLL.IN,
                .revents = 0,
            }};
            const rc = std.posix.poll(&fds, @intCast(self.response_timeout_ms)) catch |err| {
                return step.fail("failed while waiting for response: {t}", .{err});
            };
            if (rc == 0) {
                return step.fail("timed out waiting for response headers after {d}ms", .{self.response_timeout_ms});
            }
        };

        var redirect_buf: [4096]u8 = undefined;
        const resp = req.receiveHead(redirect_buf[0..]) catch |err| {
            if (err == error.ReadFailed) {
                if (req.connection) |conn| if (conn.getReadError()) |read_err| {
                    return step.fail("failed to receive response from {s}: {t} ({t})", .{ self.url, err, read_err });
                };
            }
            return step.fail("failed to receive response from {s}: {t}", .{ self.url, err });
        };

        const code: u16 = @intFromEnum(resp.head.status);
        if (code < 200 or code >= 300) {
            return step.fail("upload failed: HTTP {d} {s}", .{ code, resp.head.reason });
        }

        req.deinit();
        client.deinit();
    }
};

const HostPort = struct {
    host: []const u8,
    port: u16,
};

const ResolvedHostPort = union(enum) {
    ok: HostPort,
    err: []const u8,
};

fn resolveHostPort(b: *std.Build, opts: UploadOptions) ResolvedHostPort {
    const host_cli = b.option([]const u8, opts.host_option_name, "Paper Portal dev server hostname or IP address");
    const port_cli = b.option(u16, opts.port_option_name, "Paper Portal dev server port number");

    const host_env = getEnvString(b, opts.host_env_var);
    const port_env = getEnvString(b, opts.port_env_var);

    const host = host_cli orelse host_env orelse opts.default_host;
    if (host.len == 0) return .{ .err = b.fmt("{s} is empty (set -D{s}=... or {s})", .{ opts.host_option_name, opts.host_option_name, opts.host_env_var }) };

    const port: u16 = port_cli orelse blk: {
        const s = port_env orelse break :blk opts.default_port;
        if (s.len == 0) {
            return .{ .err = b.fmt("{s} is empty (set -D{s}=... or {s})", .{ opts.port_option_name, opts.port_option_name, opts.port_env_var }) };
        }
        break :blk std.fmt.parseInt(u16, s, 10) catch {
            return .{ .err = b.fmt("invalid {s}={s} (must be an integer 0-65535)", .{ opts.port_env_var, s }) };
        };
    };

    return .{ .ok = .{ .host = host, .port = port } };
}

fn getEnvString(b: *std.Build, name: []const u8) ?[]const u8 {
    return b.graph.environ_map.get(name);
}

/// Formats `http://host:port/path` and wraps IPv6 hosts in brackets.
fn formatUrl(b: *std.Build, host: []const u8, port: u16, endpoint_path: []const u8) []const u8 {
    const host_for_url = hostForUrl(b, host);
    const path = if (endpoint_path.len == 0)
        "/"
    else if (endpoint_path[0] == '/')
        endpoint_path
    else
        b.fmt("/{s}", .{endpoint_path});
    return b.fmt("http://{s}:{d}{s}", .{ host_for_url, port, path });
}

fn hostForUrl(b: *std.Build, host: []const u8) []const u8 {
    if (host.len > 0 and host[0] == '[') return host;
    if (std.mem.indexOfScalar(u8, host, ':') != null) {
        return b.fmt("[{s}]", .{host});
    }
    return host;
}

fn dirExists(b: *std.Build, rel: []const u8) bool {
    std.Io.Dir.cwd().access(b.graph.io, rel, .{}) catch return false;
    return true;
}
