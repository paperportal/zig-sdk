const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

/// Enqueue asynchronous devserver startup.
pub fn start() Error!void {
    try errors.check(ffi.devserver_start());
}

pub fn stop() Error!void {
    try errors.check(ffi.devserver_stop());
}

pub fn is_running() bool {
    return ffi.devserver_is_running() > 0;
}

pub fn is_starting() bool {
    return ffi.devserver_is_starting() > 0;
}

fn slice_from_rc(rc: i32, buffer: []u8) errors.Error![]const u8 {
    if (rc < 0) return errors.fromCode(rc);
    return buffer[0..@intCast(rc)];
}

pub fn get_url(buffer: []u8) Error![]const u8 {
    return slice_from_rc(ffi.devserver_get_url(buffer.ptr, buffer.len), buffer);
}

pub fn get_ap_ssid(buffer: []u8) Error![]const u8 {
    return slice_from_rc(ffi.devserver_get_ap_ssid(buffer.ptr, buffer.len), buffer);
}

pub fn get_ap_password(buffer: []u8) Error![]const u8 {
    return slice_from_rc(ffi.devserver_get_ap_password(buffer.ptr, buffer.len), buffer);
}

pub fn get_last_error(buffer: []u8) Error![]const u8 {
    return slice_from_rc(ffi.devserver_get_last_error(buffer.ptr, buffer.len), buffer);
}
