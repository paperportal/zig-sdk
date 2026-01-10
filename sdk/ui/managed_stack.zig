const std = @import("std");
const scene = @import("scene.zig");

var g_created: bool = false;
var g_stack: scene.SceneStack = undefined;

fn ensureStack() *scene.SceneStack {
    if (!g_created) {
        g_stack = scene.SceneStack.init(std.heap.wasm_allocator, 0);
        g_created = true;
    }
    return &g_stack;
}

pub fn deinitStack() void {
    if (!g_created) return;
    g_stack.deinit();
    g_created = false;
}

pub fn set(s: scene.Scene) anyerror!void {
    try ensureStack().set(s);
}

pub fn push(s: scene.Scene) anyerror!void {
    try ensureStack().push(s);
}

pub fn replace(s: scene.Scene) anyerror!void {
    try ensureStack().replace(s);
}

pub fn pop() anyerror!void {
    try ensureStack().pop();
}

pub fn redraw() anyerror!void {
    try ensureStack().redraw();
}

pub fn handleGesture(ev: scene.GestureEvent) anyerror!void {
    try ensureStack().handleGesture(ev);
}

pub fn handleGestureFromArgs(
    kind: i32,
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    duration_ms: i32,
    now_ms: i32,
    flags: i32,
) anyerror!void {
    try ensureStack().handleGestureFromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags);
}
