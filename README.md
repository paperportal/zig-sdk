# Zig Paper Portal SDK

This directory contains a small Zig wrapper around the Paper Portal host APIs
for WASM applications.

## Structure

- `sdk.zig`: top-level import that re-exports the submodules.
- `sdk/`: individual modules (`core`, `display`, `touch`, `fs`, `nvs`, `error`).

## Usage

- Add to zig project with: `zig fetch --save git+https://github.com/paperportal/zig-sdk`
- Then to wasm with: `zig build -Dtarget=wasm32-wasi -Doptimize=ReleaseSmall`

In a Zig WASM module, add the SDK as a module search path and import it:

    const sdk = @import("paper_portal_sdk");
    const display = sdk.display;

## Build helper: `zig build upload`

`zig-sdk` ships a small build helper that adds an `upload` step which POSTs your
generated `.wasm` to the Paper Portal device dev server:

    const pp_sdk = @import("paper_portal_sdk");

    _ = pp_sdk.addWasmUpload(b, exe, .{});

Configuration precedence is:

1) CLI (`-Dpaperportal-host=...`, `-Dpaperportal-port=...`)
2) Environment (`PAPERPORTAL_HOST`, `PAPERPORTAL_PORT`)
3) Defaults (`portal.local:80`)

Example:

    zig build upload -Dpaperportal-host=portal.local -Dpaperportal-port=80

This step is implemented in pure Zig (no `curl` dependency).
