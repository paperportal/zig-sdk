# Repository Guidelines

## Project Structure & Module Organization

- `sdk.zig`: public entrypoint that re-exports the SDK modules.
- `sdk/`: WASM host API wrappers (e.g. `core.zig`, `display.zig`, `touch.zig`, `fs.zig`, `net.zig`, `nvs.zig`).
- `build_support/`: build-time helpers used by consumers via `@import("paper_portal_sdk")` (upload step and `.papp` packaging).
- `build.zig` / `build.zig.zon`: package definition.
- Generated: `.zig-cache/` and `zig-out/` (ignored by git).

## Build, Test, and Development Commands

- `zig build`: sanity-checks the package and exports the `paper_portal_sdk` module.
- `zig fmt .`: formats all Zig sources (required before opening a PR).
- `zig test build_support/manifest.zig`: runs unit tests for the packager helpers (repeat for other `build_support/*.zig` files).

## Coding Style & Naming Conventions

- Formatting: rely on `zig fmt`; avoid manual alignment/spacing tweaks.
- Naming (follow existing code): files `snake_case.zig`, types `PascalCase`, functions/fields `lowerCamelCase` (except functions that return a type (Zig), which use `PascalCase`), constants `SCREAMING_SNAKE_CASE` (e.g. `display.colors.BLACK`).
- Keep the SDK as a thin wrapper over host FFI (`sdk/ffi.zig`): prefer small, well-named helpers over deep abstractions.
