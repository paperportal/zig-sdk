const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const TouchPoint = struct {
    x: i32,
    y: i32,
    state: u8,
};

const TOUCH_DETAIL_SIZE: usize = 24;
const TOUCH_STATE_OFFSET: usize = 20;

pub fn getCount() i32 {
    return ffi.touchGetCount();
}

pub fn readTouch() Error!?TouchPoint {
    if (ffi.touchGetCount() <= 0) return null;

    var buf: [TOUCH_DETAIL_SIZE]u8 = undefined;
    try errors.check(ffi.touchGetDetail(0, &buf, buf.len));

    const x = @as(i32, std.mem.readInt(i16, buf[0..2], .little));
    const y = @as(i32, std.mem.readInt(i16, buf[2..4], .little));
    const state = buf[TOUCH_STATE_OFFSET];

    return TouchPoint{ .x = x, .y = y, .state = state };
}
