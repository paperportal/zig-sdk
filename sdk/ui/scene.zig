const std = @import("std");

/// Display/UI primitives built on top of Paper Portal's gesture callbacks.
///
/// This module is pure Zig (no host FFI). Apps are expected to:
/// - Set an initial scene in `ppInit` (use `SceneStack.setInitial()` or `reset()`).
/// - Forward `ppOnGesture` to `SceneStack.handleGestureFromArgs()`.
/// - Optionally forward `ppTick` to `SceneStack.tick()`.
pub const Context = struct {
    allocator: std.mem.Allocator,
    screen_w: i32,
    screen_h: i32,
};

pub const GestureKind = enum(i32) {
    unknown = 0,
    tap = 1,
    long_press = 2,
    flick = 3,
    drag_start = 4,
    drag_move = 5,
    drag_end = 6,
};

pub const GestureEvent = struct {
    kind: GestureKind,
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    duration_ms: i32,
    now_ms: i32,
    flags: i32,

    pub fn fromArgs(kind: i32, x: i32, y: i32, dx: i32, dy: i32, duration_ms: i32, now_ms: i32, flags: i32) GestureEvent {
        return .{
            .kind = kindFromI32(kind),
            .x = x,
            .y = y,
            .dx = dx,
            .dy = dy,
            .duration_ms = duration_ms,
            .now_ms = now_ms,
            .flags = flags,
        };
    }
};

fn kindFromI32(v: i32) GestureKind {
    return switch (v) {
        1 => .tap,
        2 => .long_press,
        3 => .flick,
        4 => .drag_start,
        5 => .drag_move,
        6 => .drag_end,
        else => .unknown,
    };
}

pub const Scene = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        draw: *const fn (ptr: *anyopaque, ctx: *Context) anyerror!void,
        onEnter: ?*const fn (ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void = null,
        onExit: ?*const fn (ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void = null,
        onPause: ?*const fn (ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void = null,
        onResume: ?*const fn (ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void = null,
        onGesture: ?*const fn (ptr: *anyopaque, ctx: *Context, nav: *Navigator, ev: GestureEvent) anyerror!void = null,
        tick: ?*const fn (ptr: *anyopaque, ctx: *Context, nav: *Navigator, now_ms: i32) anyerror!void = null,
    };

    /// Build a `Scene` from an app-owned scene object.
    ///
    /// Required methods on `T`:
    /// - `pub fn draw(self: *T, ctx: *Context) anyerror!void`
    ///
    /// Optional methods on `T` (exact signatures):
    /// - `onEnter(self: *T, ctx: *Context, nav: *Navigator) anyerror!void`
    /// - `onExit(self: *T, ctx: *Context, nav: *Navigator) anyerror!void`
    /// - `onPause(self: *T, ctx: *Context, nav: *Navigator) anyerror!void`
    /// - `onResume(self: *T, ctx: *Context, nav: *Navigator) anyerror!void`
    /// - `onGesture(self: *T, ctx: *Context, nav: *Navigator, ev: GestureEvent) anyerror!void`
    /// - `tick(self: *T, ctx: *Context, nav: *Navigator, now_ms: i32) anyerror!void`
    pub fn from(comptime T: type, scene: *T) Scene {
        comptime {
            if (!@hasDecl(T, "draw")) {
                @compileError("ui.Scene.from(" ++ @typeName(T) ++ "): missing required method draw(self: *T, ctx: *ui.Context) anyerror!void");
            }
        }

        const has_onEnter = @hasDecl(T, "onEnter");
        const has_onExit = @hasDecl(T, "onExit");
        const has_onPause = @hasDecl(T, "onPause");
        const has_onResume = @hasDecl(T, "onResume");
        const has_onGesture = @hasDecl(T, "onGesture");
        const has_tick = @hasDecl(T, "tick");

        const Gen = struct {
            fn cast(ptr: *anyopaque) *T {
                return @ptrCast(@alignCast(ptr));
            }

            fn draw(ptr: *anyopaque, ctx: *Context) anyerror!void {
                return @call(.auto, T.draw, .{ cast(ptr), ctx });
            }

            fn onEnter(ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void {
                if (comptime !has_onEnter) unreachable;
                return @call(.auto, T.onEnter, .{ cast(ptr), ctx, nav });
            }

            fn onExit(ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void {
                if (comptime !has_onExit) unreachable;
                return @call(.auto, T.onExit, .{ cast(ptr), ctx, nav });
            }

            fn onPause(ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void {
                if (comptime !has_onPause) unreachable;
                return @call(.auto, T.onPause, .{ cast(ptr), ctx, nav });
            }

            fn onResume(ptr: *anyopaque, ctx: *Context, nav: *Navigator) anyerror!void {
                if (comptime !has_onResume) unreachable;
                return @call(.auto, T.onResume, .{ cast(ptr), ctx, nav });
            }

            fn onGesture(ptr: *anyopaque, ctx: *Context, nav: *Navigator, ev: GestureEvent) anyerror!void {
                if (comptime !has_onGesture) unreachable;
                return @call(.auto, T.onGesture, .{ cast(ptr), ctx, nav, ev });
            }

            fn tick(ptr: *anyopaque, ctx: *Context, nav: *Navigator, now_ms: i32) anyerror!void {
                if (comptime !has_tick) unreachable;
                return @call(.auto, T.tick, .{ cast(ptr), ctx, nav, now_ms });
            }

            const vtable = VTable{
                .draw = draw,
                .onEnter = if (has_onEnter) onEnter else null,
                .onExit = if (has_onExit) onExit else null,
                .onPause = if (has_onPause) onPause else null,
                .onResume = if (has_onResume) onResume else null,
                .onGesture = if (has_onGesture) onGesture else null,
                .tick = if (has_tick) tick else null,
            };
        };

        return .{
            .ptr = scene,
            .vtable = &Gen.vtable,
        };
    }
};

pub const SceneStack = struct {
    allocator: std.mem.Allocator,
    ctx: Context,
    scenes: std.ArrayListUnmanaged(Scene) = .{},
    max_scenes: usize,

    pub const StackError = error{
        NotInitialized,
        AlreadyInitialized,
        StackFull,
        StackEmpty,
        CannotPopRoot,
    };

    pub fn init(allocator: std.mem.Allocator, screen_w: i32, screen_h: i32, max_scenes: usize) SceneStack {
        return .{
            .allocator = allocator,
            .ctx = .{
                .allocator = allocator,
                .screen_w = screen_w,
                .screen_h = screen_h,
            },
            .max_scenes = max_scenes,
        };
    }

    pub fn deinit(self: *SceneStack) void {
        self.scenes.deinit(self.allocator);
        self.* = undefined;
    }

    pub fn isInitialized(self: *const SceneStack) bool {
        return self.scenes.items.len != 0;
    }

    pub fn len(self: *const SceneStack) usize {
        return self.scenes.items.len;
    }

    pub fn reset(self: *SceneStack, scene: Scene) anyerror!void {
        var nav = Navigator{ .stack = self };

        // Best-effort exit callbacks.
        var i: usize = self.scenes.items.len;
        while (i > 0) : (i -= 1) {
            const s = self.scenes.items[i - 1];
            if (s.vtable.onExit) |f| {
                f(s.ptr, &self.ctx, &nav) catch {};
            }
        }

        self.scenes.items.len = 0;
        try self.pushRootInternal(scene);
    }

    pub fn setInitial(self: *SceneStack, scene: Scene) anyerror!void {
        if (self.scenes.items.len != 0) return StackError.AlreadyInitialized;
        try self.pushRootInternal(scene);
    }

    pub fn push(self: *SceneStack, scene: Scene) anyerror!void {
        if (self.max_scenes != 0 and self.scenes.items.len >= self.max_scenes) return StackError.StackFull;

        var nav = Navigator{ .stack = self };
        const prev = self.top();
        if (prev) |p| {
            if (p.vtable.onPause) |f| {
                try f(p.ptr, &self.ctx, &nav);
            }
        }

        const old_len = self.scenes.items.len;
        try self.scenes.append(self.allocator, scene);
        errdefer self.scenes.items.len = old_len;

        const cur = self.top().?;
        if (cur.vtable.onEnter) |f| {
            f(cur.ptr, &self.ctx, &nav) catch |err| {
                self.scenes.items.len = old_len;
                if (prev) |p| {
                    if (p.vtable.onResume) |r| {
                        r(p.ptr, &self.ctx, &nav) catch {};
                    }
                }
                return err;
            };
        }

        cur.vtable.draw(cur.ptr, &self.ctx) catch |err| {
            self.scenes.items.len = old_len;
            if (prev) |p| {
                if (p.vtable.onResume) |r| {
                    r(p.ptr, &self.ctx, &nav) catch {};
                }
            }
            return err;
        };
    }

    /// Replace only the top scene, keeping the back stack below it.
    pub fn set(self: *SceneStack, scene: Scene) anyerror!void {
        if (self.scenes.items.len == 0) return StackError.NotInitialized;

        var nav = Navigator{ .stack = self };
        const idx = self.scenes.items.len - 1;
        const old = self.scenes.items[idx];

        if (old.vtable.onExit) |f| {
            try f(old.ptr, &self.ctx, &nav);
        }

        self.scenes.items[idx] = scene;
        errdefer self.scenes.items[idx] = old;

        const cur = &self.scenes.items[idx];
        if (cur.vtable.onEnter) |f| {
            try f(cur.ptr, &self.ctx, &nav);
        }
        try cur.vtable.draw(cur.ptr, &self.ctx);
    }

    pub fn pop(self: *SceneStack) anyerror!void {
        if (self.scenes.items.len == 0) return StackError.StackEmpty;
        if (self.scenes.items.len == 1) return StackError.CannotPopRoot;

        var nav = Navigator{ .stack = self };

        const old_len = self.scenes.items.len;
        const old = self.scenes.items[old_len - 1];

        if (old.vtable.onExit) |f| {
            try f(old.ptr, &self.ctx, &nav);
        }

        self.scenes.items.len = old_len - 1;
        const cur = self.top().?;

        if (cur.vtable.onResume) |f| {
            try f(cur.ptr, &self.ctx, &nav);
        }
        try cur.vtable.draw(cur.ptr, &self.ctx);
    }

    pub fn redraw(self: *SceneStack) anyerror!void {
        const cur = self.top() orelse return StackError.NotInitialized;
        try cur.vtable.draw(cur.ptr, &self.ctx);
    }

    pub fn handleGesture(self: *SceneStack, ev: GestureEvent) anyerror!void {
        const cur = self.top() orelse return StackError.NotInitialized;
        if (cur.vtable.onGesture) |f| {
            var nav = Navigator{ .stack = self };
            try f(cur.ptr, &self.ctx, &nav, ev);
        }
    }

    pub fn handleGestureFromArgs(
        self: *SceneStack,
        kind: i32,
        x: i32,
        y: i32,
        dx: i32,
        dy: i32,
        duration_ms: i32,
        now_ms: i32,
        flags: i32,
    ) anyerror!void {
        try self.handleGesture(GestureEvent.fromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags));
    }

    pub fn tick(self: *SceneStack, now_ms: i32) anyerror!void {
        const cur = self.top() orelse return;
        if (cur.vtable.tick) |f| {
            var nav = Navigator{ .stack = self };
            try f(cur.ptr, &self.ctx, &nav, now_ms);
        }
    }

    fn top(self: *SceneStack) ?*Scene {
        if (self.scenes.items.len == 0) return null;
        return &self.scenes.items[self.scenes.items.len - 1];
    }

    fn pushRootInternal(self: *SceneStack, scene: Scene) anyerror!void {
        if (self.max_scenes != 0 and self.max_scenes < 1) return StackError.StackFull;

        const old_len = self.scenes.items.len;
        try self.scenes.append(self.allocator, scene);
        errdefer self.scenes.items.len = old_len;

        var nav = Navigator{ .stack = self };
        const cur = self.top().?;
        if (cur.vtable.onEnter) |f| {
            try f(cur.ptr, &self.ctx, &nav);
        }
        try cur.vtable.draw(cur.ptr, &self.ctx);
    }
};

pub const Navigator = struct {
    stack: *SceneStack,

    pub fn push(self: *Navigator, scene: Scene) anyerror!void {
        try self.stack.push(scene);
    }

    pub fn set(self: *Navigator, scene: Scene) anyerror!void {
        try self.stack.set(scene);
    }

    pub fn reset(self: *Navigator, scene: Scene) anyerror!void {
        try self.stack.reset(scene);
    }

    pub fn pop(self: *Navigator) anyerror!void {
        try self.stack.pop();
    }

    pub fn redraw(self: *Navigator) anyerror!void {
        try self.stack.redraw();
    }
};

test "SceneStack basic navigation order" {
    var log: std.ArrayList(u8) = .empty;
    defer log.deinit(std.testing.allocator);

    const T = struct {
        id: u8,
        log: *std.ArrayList(u8),

        fn write(self: *@This(), ch: u8) void {
            self.log.append(std.testing.allocator, ch) catch @panic("OOM");
        }

        pub fn draw(self: *@This(), ctx: *Context) anyerror!void {
            _ = ctx;
            self.write('d');
        }

        pub fn onEnter(self: *@This(), ctx: *Context, nav: *Navigator) anyerror!void {
            _ = ctx;
            _ = nav;
            self.write('e');
        }

        pub fn onPause(self: *@This(), ctx: *Context, nav: *Navigator) anyerror!void {
            _ = ctx;
            _ = nav;
            self.write('p');
        }

        pub fn onResume(self: *@This(), ctx: *Context, nav: *Navigator) anyerror!void {
            _ = ctx;
            _ = nav;
            self.write('r');
        }

        pub fn onExit(self: *@This(), ctx: *Context, nav: *Navigator) anyerror!void {
            _ = ctx;
            _ = nav;
            self.write('x');
        }
    };

    var s1 = T{ .id = 1, .log = &log };
    var s2 = T{ .id = 2, .log = &log };
    var s3 = T{ .id = 3, .log = &log };

    var stack = SceneStack.init(std.testing.allocator, 960, 540, 8);
    defer stack.deinit();

    // setInitial: enter then draw
    try stack.setInitial(Scene.from(T, &s1));
    try std.testing.expectEqualStrings("ed", log.items);

    // push: pause prev, enter new, draw new
    try stack.push(Scene.from(T, &s2));
    try std.testing.expectEqualStrings("edped", log.items);

    // set (replace top): exit old top, enter new, draw new
    try stack.set(Scene.from(T, &s3));
    try std.testing.expectEqualStrings("edpedxed", log.items);

    // pop: exit top, resume below, draw below
    try stack.pop();
    try std.testing.expectEqualStrings("edpedxedxrd", log.items);
}

test "SceneStack reset clears and draws new root" {
    var log: std.ArrayList(u8) = .empty;
    defer log.deinit(std.testing.allocator);

    const T = struct {
        log: *std.ArrayList(u8),

        fn write(self: *@This(), ch: u8) void {
            self.log.append(std.testing.allocator, ch) catch @panic("OOM");
        }

        pub fn draw(self: *@This(), ctx: *Context) anyerror!void {
            _ = ctx;
            self.write('d');
        }

        pub fn onEnter(self: *@This(), ctx: *Context, nav: *Navigator) anyerror!void {
            _ = ctx;
            _ = nav;
            self.write('e');
        }

        pub fn onExit(self: *@This(), ctx: *Context, nav: *Navigator) anyerror!void {
            _ = ctx;
            _ = nav;
            self.write('x');
        }
    };

    var a = T{ .log = &log };
    var b = T{ .log = &log };
    var c = T{ .log = &log };

    var stack = SceneStack.init(std.testing.allocator, 100, 100, 8);
    defer stack.deinit();

    try stack.setInitial(Scene.from(T, &a));
    try stack.push(Scene.from(T, &b));
    try std.testing.expect(stack.len() == 2);

    // reset: best-effort exits (top to bottom), then enter+draw new root
    try stack.reset(Scene.from(T, &c));
    try std.testing.expect(stack.len() == 1);
    try std.testing.expectEqualStrings("ededxxed", log.items);
}

test "pop on root returns CannotPopRoot" {
    const T = struct {
        pub fn draw(self: *@This(), ctx: *Context) anyerror!void {
            _ = self;
            _ = ctx;
        }
    };

    var t = T{};
    var stack = SceneStack.init(std.testing.allocator, 1, 1, 8);
    defer stack.deinit();

    try stack.setInitial(Scene.from(T, &t));
    try std.testing.expectError(SceneStack.StackError.CannotPopRoot, stack.pop());
}
