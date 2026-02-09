# Zig Paper Portal SDK

This directory contains a small Zig wrapper around the Paper Portal host APIs
for WASM applications.

## Structure

- `sdk.zig`: top-level import that re-exports the submodules.
- `sdk/`: individual modules (`core`, `display`, `touch`, `fs`, `nvs`, `socket`, `error`).

## Usage

- Add to zig project with: `zig fetch --save git+https://github.com/paperportal/zig-sdk`
- Then to wasm with: `zig build -Dtarget=wasm32-wasi -Doptimize=ReleaseSmall`

In a Zig WASM module, add the SDK as a module search path and import it:

    const sdk = @import("paper_portal_sdk");
    const display = sdk.display;

## App lifecycle

Switch to another app:

    try sdk.core.open_app("settings", null);

Exit current app and return to launcher:

    try sdk.core.exit_app();

## UI scenes

The SDK provides a small scene stack to help structure UI apps around the host's
`pp_on_gesture` callback.

Minimal usage:

    const std = @import("std");
    const sdk = @import("paper_portal_sdk");
    const ui = sdk.ui;

    const allocator = std.heap.wasm_allocator;

    const MainScene = struct {
        pub fn draw(self: *MainScene, ctx: *ui.Context) anyerror!void {
            _ = self;
            _ = ctx;
            // draw using sdk.display, then refresh
        }

        pub fn onGesture(self: *MainScene, ctx: *ui.Context, nav: *ui.Navigator, ev: ui.GestureEvent) anyerror!void {
            _ = self;
            _ = ctx;
            _ = nav;
            _ = ev;
            // handle tap/drag/etc
        }
    };

    var g_stack: ui.SceneStack = undefined;
    var g_main: MainScene = .{};

    pub export fn pp_init(api_version: i32, screen_w: i32, screen_h: i32, args_ptr: i32, args_len: i32) i32 {
        _ = api_version;
        _ = args_ptr;
        _ = args_len;
        sdk.core.begin() catch return -1;

        g_stack = ui.SceneStack.init(allocator, screen_w, screen_h, 8);
        g_stack.setInitial(ui.Scene.from(MainScene, &g_main)) catch return -1;
        return 0;
    }

    pub export fn pp_on_gesture(kind: i32, x: i32, y: i32, dx: i32, dy: i32, duration_ms: i32, now_ms: i32, flags: i32) i32 {
        g_stack.handleGestureFromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags) catch {};
        return 0;
    }

    pub export fn pp_tick(now_ms: i32) i32 {
        g_stack.tick(now_ms) catch {};
        return 0;
    }

## Devserver startup semantics

`sdk.devserver.start()` is asynchronous. After calling `start()`, poll:
- `sdk.devserver.is_starting()` for in-progress startup
- `sdk.devserver.is_running()` for ready state
- `sdk.devserver.get_last_error()` for the most recent startup/runtime error message


## Sockets

Example TCP listener:

    const sdk = @import("paper_portal_sdk");

    pub fn serve() !void {
        var s = try sdk.socket.Socket.tcp();
        defer s.close() catch {};

        try s.bind(sdk.socket.SocketAddr.any(8080));
        try s.listen(5);

        const client = try s.accept();
        defer client.socket.close() catch {};

        var buf: [256]u8 = undefined;
        const n = try client.socket.recv(buf[0..], 1000);
        _ = try client.socket.send(buf[0..n], 1000);
    }

## Build helper: `zig build upload`

`zig-sdk` ships a small build helper that adds an `upload` step which POSTs your
generated `.wasm` to the Paper Portal device dev server:

    const sdk = @import("paper_portal_sdk");

    _ = sdk.addWasmUpload(b, exe, .{});

## Build helper: `sdk.addPortalApp` (one-call app setup)

If your project follows the standard Paper Portal WASM layout, you can use
`sdk.addPortalApp()` to set up the target, root module, exports, SDK import,
`upload` step, memory settings, and install steps in one call:

    const sdk = @import("paper_portal_sdk");

    const app = sdk.addPortalApp(b, .{
        .os_tag = .freestanding,
        .export_symbol_names = &.{
            "pp_init",
            "pp_shutdown",
            "pp_on_gesture",
        },
    });

    const install_step = b.addInstallFile(app.exe.getEmittedBin(), "../../main/assets/entrypoint.wasm");
    b.getInstallStep().dependOn(&install_step.step);

Configuration precedence is:

1) CLI (`-Dpaperportal-host=...`, `-Dpaperportal-port=...`)
2) Environment (`PAPERPORTAL_HOST`, `PAPERPORTAL_PORT`)
3) Defaults (`portal.local:80`)

Example:

    zig build upload -Dpaperportal-host=portal.local -Dpaperportal-port=80

This step is implemented in pure Zig (no `curl` dependency).

## Build helper: `zig build package` (create `.papp`)

`zig-sdk` can also generate Paper Portal app packages (`.papp`), matching
`portal/docs/specs/spec-app-packaging.md`.

### Minimal usage

This is the simplest addition to `build.zig` for building Paper Portal app
package. Replace the id with an unique generated UUID that is used only for
this app.

    const sdk = @import("paper_portal_sdk");

    _ = sdk.addPortalPackage(b, exe, .{
        .manifest = .{
            .id = "00000000-0000-0000-0000-000000000000",
            .name = "Notes",
            .version = "1.0.0",
        },
    });

Then run:

    zig build package

By default the output is installed to `zig-out/<name>-<version>.papp`.

### API (everything you can configure)

The packaging helper is configured via `sdk.PappOptions` and returns a
`sdk.PortalPackage`.

You can call `sdk.addPortalPackage(b, wasm_artifact, opts)`.

#### `PappOptions`

- `step_name: []const u8 = "package"`: The build step name (`zig build <step_name>`).
- `step_description: []const u8 = "Build a Paper Portal .papp package"`: Help text for the step.
- `manifest: ManifestOptions` (**required**): Inputs used to populate `manifest.json`.
- `icon_png: ?std.Build.LazyPath = null`: Optional icon file to add as `icon.png` in the ZIP.
- `assets_dir: ?std.Build.LazyPath = null`: Optional directory to include as `assets/**` in the ZIP.
- `output_basename: ?[]const u8 = null`: Output filename (extension `.papp` is appended if missing).
  - Default is `<name>-<version>.papp` with `name` sanitized for filesystem safety.
- `compression: CompressionOptions = .{}`: Per-entry ZIP compression policy.
- `signing: ?SigningOptions = null`: Optional Ed25519 signing configuration.

#### `ManifestOptions`

- `manifest_version: u32 = 1`: Must match the Runner-supported manifest schema.
- `sdk_version: u32 = 1`: Must match the Runner-supported SDK/contract version.
- `id: []const u8` (**required**): Canonical lower-case UUID string.
- `name: []const u8` (**required**): Display name (also used for default filename).
- `version: []const u8` (**required**): Strict `#.#.#` digits-only format.
- Optional metadata (all default to `null` and omitted from JSON when unset):
  - `description`, `author`, `home_page`, `copyright`

Notes:
- `manifest.json.checksum` is always computed by the packager as `sha256:<64 lower-hex>` over the exact (uncompressed) `app.wasm` bytes.

#### `CompressionOptions`

Values are `sdk.ZipCompression` (`.store` or `.deflate`).

- `wasm: .deflate` (default): Compress `app.wasm` with deflate (raw DEFLATE stream).
- `manifest: .store` (default): Store `manifest.json` uncompressed.
- `icon: .store` (default): Store `icon.png` uncompressed.
- `assets: .store` (default): Store all `assets/**` files uncompressed.

Notes:
- The ZIP writer enforces `.papp` constraints: no encryption and no ZIP64.

#### `SigningOptions`

When `PappOptions.signing` is non-null, the packager fills `manifest.json` with:
- `publisher_pubkey` (Base64, 32 bytes decoded)
- `signature` (Base64, 64 bytes decoded)

Fields:
- `seed_b64: ?[]const u8 = null`: Base64-encoded 32-byte Ed25519 seed (highest precedence).
- `seed_option_name: []const u8 = "paperportal-publisher-seed-b64"`: CLI override name.
- `seed_env_var: []const u8 = "PAPERPORTAL_PUBLISHER_SEED_B64"`: Environment override name.
- `deterministic: bool = true`: Deterministic signatures (reproducible builds).

Seed selection precedence:
1) `SigningOptions.seed_b64`
2) CLI: `-Dpaperportal-publisher-seed-b64=...`
3) Environment: `PAPERPORTAL_PUBLISHER_SEED_B64`

#### `PortalPackage`

Returned from `addPortalPackage`:
- `step: *std.Build.Step`: The top-level build step for packaging.
- `getEmittedPapp() std.Build.LazyPath`: The generated `.papp` file (for wiring into other steps).

### Examples

Enable icon + assets:

    _ = sdk.addPortalPackage(b, exe, .{
        .manifest = .{ .id = "...", .name = "MyApp", .version = "1.0.0" },
        .icon_png = b.path("icon.png"),
        .assets_dir = b.path("assets"),
    });

Enable signing:

    _ = sdk.addPortalPackage(b, exe, .{
        .manifest = .{ .id = "...", .name = "MyApp", .version = "1.0.0" },
        .signing = .{},
    });

Then provide the seed via `-Dpaperportal-publisher-seed-b64=...` or `PAPERPORTAL_PUBLISHER_SEED_B64`.
