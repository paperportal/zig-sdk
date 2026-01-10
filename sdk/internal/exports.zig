const std = @import("std");
const core = @import("../core.zig");
const microtask = @import("../microtask.zig");
const ui = @import("../ui.zig");

pub fn portalContractVersion() callconv(.c) i32 {
    return 1;
}

pub fn portalAlloc(len: i32) callconv(.c) i32 {
    if (len <= 0) return 0;
    const size: usize = @intCast(len);
    const buf = std.heap.wasm_allocator.alloc(u8, size) catch return 0;
    return @intCast(@intFromPtr(buf.ptr));
}

pub fn portalFree(ptr: i32, len: i32) callconv(.c) void {
    if (ptr == 0 or len <= 0) return;
    const size: usize = @intCast(len);
    const addr: usize = @intCast(ptr);
    const buf = @as([*]u8, @ptrFromInt(addr))[0..size];
    std.heap.wasm_allocator.free(buf);
}

pub fn portalInit(api_version: i32, args_ptr: i32, args_len: i32) callconv(.c) i32 {
    _ = api_version;
    _ = args_ptr;
    _ = args_len;
    core.log.info("PPINIT!!!!");
    return 0;
}

pub fn portalMicroTaskStep(handle: i32, now_ms: i32) callconv(.c) i64 {
    return microtask.dispatch(handle, now_ms);
}

pub fn portalGesture(
    kind: i32,
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    duration_ms: i32,
    now_ms: i32,
    flags: i32,
) callconv(.c) i32 {
    ui.scene.handleGestureFromArgs(kind, x, y, dx, dy, duration_ms, now_ms, flags) catch |err| {
        switch (err) {
            ui.SceneStack.StackError.NotInitialized => {},
            else => core.log.ferr("portalGesture: handleGesture failed: {s}", .{@errorName(err)}),
        }
    };
    return 0;
}
