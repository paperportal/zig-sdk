const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Temp = struct {
    celsius: f32,
};

fn copyBytesTo(comptime T: type, bytes: []const u8) T {
    var v: T = undefined;
    const dst = std.mem.asBytes(&v);
    const n = @min(dst.len, bytes.len);
    std.mem.copyForwards(u8, dst[0..n], bytes[0..n]);
    return v;
}

pub fn begin() Error!void {
    try errors.check(ffi.imuBegin());
}

pub fn isEnabled() bool {
    return ffi.imuIsEnabled() > 0;
}

pub fn update() Error!void {
    try errors.check(ffi.imuUpdate());
}

pub fn getAccel() Error!Vec3 {
    var buf: [@sizeOf(Vec3)]u8 = undefined;
    try errors.check(ffi.imuGetAccel(&buf, buf.len));
    return copyBytesTo(Vec3, buf[0..]);
}

pub fn getGyro() Error!Vec3 {
    var buf: [@sizeOf(Vec3)]u8 = undefined;
    try errors.check(ffi.imuGetGyro(&buf, buf.len));
    return copyBytesTo(Vec3, buf[0..]);
}

pub fn getTemp() Error!Temp {
    var buf: [@sizeOf(Temp)]u8 = undefined;
    try errors.check(ffi.imuGetTemp(&buf, buf.len));
    return copyBytesTo(Temp, buf[0..]);
}
