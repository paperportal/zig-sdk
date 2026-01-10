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
    try errors.check(ffi.imu_begin());
}

pub fn is_enabled() bool {
    return ffi.imu_is_enabled() > 0;
}

pub fn update() Error!void {
    try errors.check(ffi.imu_update());
}

pub fn get_accel() Error!Vec3 {
    var buf: [@sizeOf(Vec3)]u8 = undefined;
    try errors.check(ffi.imu_get_accel(&buf, buf.len));
    return copyBytesTo(Vec3, buf[0..]);
}

pub fn get_gyro() Error!Vec3 {
    var buf: [@sizeOf(Vec3)]u8 = undefined;
    try errors.check(ffi.imu_get_gyro(&buf, buf.len));
    return copyBytesTo(Vec3, buf[0..]);
}

pub fn get_temp() Error!Temp {
    var buf: [@sizeOf(Temp)]u8 = undefined;
    try errors.check(ffi.imu_get_temp(&buf, buf.len));
    return copyBytesTo(Temp, buf[0..]);
}
