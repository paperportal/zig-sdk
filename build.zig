const std = @import("std");

/// Zig Paper Portal SDK package build script.
///
/// This package exports:
/// - A Zig module named `paper_portal_sdk` (see `sdk.zig`), and
/// - Convenience helpers for adding an `upload` build step to your project.
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

/// Adds an upload step that depends on the output of `wasm_artifact`.
///
/// This is a convenience wrapper around `addUploadStep` that uses
/// `wasm_artifact.getEmittedBin()` as the file to upload.
pub fn addWasmUpload(b: *std.Build, wasm_artifact: *std.Build.Step.Compile, opts: UploadOptions) *std.Build.Step {
    return addUploadStep(b, wasm_artifact.getEmittedBin(), opts);
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
