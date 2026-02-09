const std = @import("std");
const core = @import("../core.zig");

pub fn portal_contract_version() callconv(.c) i32 {
    return 1;
}

pub fn portal_alloc(len: i32) callconv(.c) i32 {
    if (len <= 0) return 0;
    const size: usize = @intCast(len);
    const buf = std.heap.wasm_allocator.alloc(u8, size) catch return 0;
    return @intCast(@intFromPtr(buf.ptr));
}

pub fn portal_free(ptr: i32, len: i32) callconv(.c) void {
    if (ptr == 0 or len <= 0) return;
    const size: usize = @intCast(len);
    const addr: usize = @intCast(ptr);
    const buf = @as([*]u8, @ptrFromInt(addr))[0..size];
    std.heap.wasm_allocator.free(buf);
}

pub fn portal_init(api_version: i32, screen_w: i32, screen_h: i32, args_ptr: i32, args_len: i32) callconv(.c) i32 {
    _ = api_version;
    _ = screen_w;
    _ = screen_h;
    _ = args_ptr;
    _ = args_len;
    core.log.info("PPINIT!!!!");
    return 0;
}
