# `paper_portal_sdk.ui`

Scene-stack UI helpers for Paper Portal WASM apps. This module is pure Zig (no host FFI) and is meant to sit on top of the host callback surface (`ppInit`, `ppOnGesture`, `ppTick`).

The SDK entrypoint re-exports this module as `sdk.ui`:

```zig
const sdk = @import("paper_portal_sdk");
const ui = sdk.ui;
```

## Quick start (single scene)

This is the minimal wiring:

- Create your scenes as app-owned structs.
- In `ppInit`, create a `ui.SceneStack` and set the initial scene.
- In `ppOnGesture`, forward the args to `SceneStack.handleGestureFromArgs`.
- (Optional) In `ppTick`, forward to `SceneStack.tick` if you need animations/time-based updates.
- (Optional) In `ppShutdown`, call `SceneStack.deinit()` to free the internal stack storage.

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

var g_stack: ui.SceneStack = undefined;
var g_main: MainScene = .{};

pub export fn ppInit(api_version: i32, screen_w: i32, screen_h: i32, args_ptr: i32, args_len: i32) i32 {
    _ = api_version;
    _ = args_ptr;
    _ = args_len;

    sdk.core.begin() catch return -1;

    g_stack = ui.SceneStack.init(allocator, screen_w, screen_h, 8);
    g_stack.setInitial(ui.Scene.from(MainScene, &g_main)) catch return -1;
    return 0;
}

pub export fn ppOnGesture(kind: i32, x: i32, y: i32, dx: i32, dy: i32, duration_ms: i32, now_ms: i32, flags: i32) i32 {
    g_stack.handleGestureFromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags) catch {};
    return 0;
}

pub export fn ppTick(now_ms: i32) i32 {
    g_stack.tick(now_ms) catch {};
    return 0;
}

pub export fn ppShutdown() i32 {
    g_stack.deinit();
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
pub fn tick(self: *T, ctx: *ui.Context, nav: *ui.Navigator, now_ms: i32) anyerror!void
```

Note: `SceneStack.handleGesture*()` only calls your scene's `onGesture`. If the gesture changes UI state, call `try nav.redraw()` (or otherwise trigger a redraw) from inside `onGesture`.

## Navigation

Use `ui.Navigator` (passed to callbacks) to change scenes:

- `nav.push(scene)` pushes a new top scene (pauses previous top).
- `nav.pop()` pops the top scene (resumes the new top).
- `nav.set(scene)` replaces only the top scene.
- `nav.reset(scene)` clears the stack and sets a new root scene.
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

The easiest integration is forwarding raw args:

```zig
try g_stack.handleGestureFromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags);
```

Or, if you already have a `GestureEvent`:

```zig
try g_stack.handleGesture(ev);
```

## `SceneStack` lifecycle and errors

- Initialize with `ui.SceneStack.init(allocator, screen_w, screen_h, max_scenes)`.
  - If `max_scenes` is `0`, the stack is unbounded.
- Call `setInitial` once (root scene). Afterwards use `push`, `pop`, `set`, or `reset`.
- `SceneStack` methods return `anyerror!void`:
  - `SceneStack.StackError` for stack-state issues (e.g. `AlreadyInitialized`, `CannotPopRoot`)
  - plus anything your scene callbacks return (and any `sdk.*` errors you propagate)

If you ignore errors in `ppOnGesture`, prefer logging them (or at least leaving them visible during development) so you can catch bugs early.
