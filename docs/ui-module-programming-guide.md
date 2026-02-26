# `paper_portal_sdk.ui`

Scene-stack UI helpers for Paper Portal WASM apps. The scene stack is pure Zig (no host FFI) and is meant to sit on top of the host callback surface (`ppInit`, `portalGesture`). The `ui.Painter` helper is a convenience layer for host-backed drawing (the same underlying surface as `sdk.display`) while providing a layout-friendly, local-coordinate API.

The SDK entrypoint re-exports this module as `sdk.ui`:

```zig
const sdk = @import("paper_portal_sdk");
const ui = sdk.ui;
```

## Quick start (single scene)

This is the minimal wiring:

- Create your scenes as app-owned structs.
- In `ppInit`, set the root scene with `ui.scene.set(...)`.
- The SDK exports `portalGesture` and routes gesture events to your top scene's `onGesture`.
- (Optional) In `ppShutdown`, call `ui.scene.deinitStack()` to free internal stack storage.

```zig
const std = @import("std");
const sdk = @import("paper_portal_sdk");
const ui = sdk.ui;

const allocator = std.heap.wasm_allocator;

const MainScene = struct {
    pub fn draw(self: *MainScene, ctx: *ui.Context) anyerror!void {
        _ = self;
        _ = ctx;

        try sdk.display.clear();
        // ...draw into back buffer...
        try sdk.display.update();
    }

    pub fn onGesture(self: *MainScene, ctx: *ui.Context, nav: *ui.Navigator, ev: ui.GestureEvent) anyerror!void {
        _ = self;
        _ = ctx;
        _ = nav;

        if (ev.kind == .tap) {
            // ...handle tap...
        }
    }
};

var g_main: MainScene = .{};

pub export fn ppInit(api_version: i32, args_ptr: i32, args_len: i32) i32 {
    _ = api_version;
    _ = args_ptr;
    _ = args_len;

    sdk.core.begin() catch return -1;

    ui.scene.set(ui.Scene.from(MainScene, &g_main)) catch return -1;
    return 0;
}

pub export fn ppShutdown() i32 {
    ui.scene.deinitStack();
    return 0;
}
```

## Defining a scene

Scenes are app-owned values. The SDK does not allocate or free scene objects; it only stores a type-erased pointer (`*anyopaque`) plus a vtable.

Create a `ui.Scene` from your concrete type with:

```zig
ui.Scene.from(MySceneType, &my_scene_value)
```

### Required method

```zig
pub fn draw(self: *T, ctx: *ui.Context) anyerror!void
```

`draw` should render the current scene state (typically via `sdk.display.*`) and then trigger a refresh (`sdk.display.update()` or `sdk.display.update_rect(...)`).

### Optional methods (exact signatures)

```zig
pub fn onEnter(self: *T, ctx: *ui.Context, nav: *ui.Navigator) anyerror!void
pub fn onExit(self: *T, ctx: *ui.Context, nav: *ui.Navigator) anyerror!void
pub fn onPause(self: *T, ctx: *ui.Context, nav: *ui.Navigator) anyerror!void
pub fn onResume(self: *T, ctx: *ui.Context, nav: *ui.Navigator) anyerror!void
pub fn onGesture(self: *T, ctx: *ui.Context, nav: *ui.Navigator, ev: ui.GestureEvent) anyerror!void
```

Note: `SceneStack.handleGesture*()` only calls your scene's `onGesture`. If the gesture changes UI state, call `try nav.redraw()` (or otherwise trigger a redraw) from inside `onGesture`.

If you need periodic work (timers, animations, background polling), use `sdk.microtask` from your scene (typically start in `onEnter` and stop in `onExit`/`onPause`). Call `ui.scene.redraw()` when your scene state changes.

## Navigation

Use `ui.Navigator` (passed to callbacks) to change scenes:

- `nav.push(scene)` pushes a new top scene (pauses previous top).
- `nav.pop()` pops the top scene (resumes the new top).
- `nav.replace(scene)` replaces only the top scene.
- `nav.set(scene)` clears the stack and sets a new root scene.
- `nav.redraw()` calls `draw` on the current top scene.

### Example: push a settings scene on tap

```zig
const SettingsScene = struct {
    pub fn draw(self: *SettingsScene, ctx: *ui.Context) anyerror!void {
        _ = self;
        _ = ctx;
        // draw settings UI
    }
};

const MainScene = struct {
    settings: SettingsScene,

    pub fn draw(self: *MainScene, ctx: *ui.Context) anyerror!void {
        _ = self;
        _ = ctx;
        // draw main UI
    }

    pub fn onGesture(self: *MainScene, ctx: *ui.Context, nav: *ui.Navigator, ev: ui.GestureEvent) anyerror!void {
        _ = ctx;
        if (ev.kind == .tap) {
            try nav.push(ui.Scene.from(SettingsScene, &self.settings));
        }
    }
};
```

## Gestures

`ui.GestureEvent` is a parsed form of the host callback arguments:

- `kind: ui.GestureKind` (`.tap`, `.long_press`, `.flick`, `.drag_start`, `.drag_move`, `.drag_end`)
- `x`, `y`: position
- `dx`, `dy`: delta (for drags/flicks)
- `duration_ms`, `now_ms`, `flags`: passthrough timing/flags values

If you need to inject synthetic events (or forward events from a custom surface), you can call:

```zig
try ui.scene.handleGestureFromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags);
```

## Stack lifecycle and errors

The SDK manages an internal scene stack. Most apps should not create a `SceneStack` themselves:

- Set your root scene with `ui.scene.set(scene)`.
- Navigate via `nav.push`, `nav.pop`, `nav.replace`, `nav.set`, and `nav.redraw` in callbacks.
- The managed stack uses `std.heap.wasm_allocator` and is unbounded.

Stack methods return `anyerror!void`:
- `SceneStack.StackError` for stack-state issues (e.g. `NotInitialized`, `CannotPopRoot`)
- plus anything your scene callbacks return (and any `sdk.*` errors you propagate)

If your `onGesture` handler ignores errors, prefer logging them (or at least leaving them visible during development) so you can catch bugs early.

## Painter

`ui.Painter` is a small value type that represents a rectangular layout region (`x`, `y`, `w`, `h`). You draw using local coordinates relative to the painter’s origin: `(0, 0)` means the painter’s top-left corner.

Painter bounds are for layout convenience only: there is no clipping/scissoring. Draw calls are allowed to overflow outside the painter’s region; painter methods only translate coordinates and perform the corresponding host-backed draw calls (equivalent to calling `sdk.display.*`).

### Example

```zig
const sdk = @import("paper_portal_sdk");
const ui = sdk.ui;

pub fn drawHello() !void {
    var screen = try ui.Painter.screen();
    var content = screen.paddedPainter(ui.Padding.all(10));

    try content.fillRect(0, 0, content.width(), content.height(), sdk.display.colors.WHITE);
    try content.drawText("Hello", 0, 0);
}
```
