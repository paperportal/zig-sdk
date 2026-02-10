const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

/// Enqueue asynchronous devserver startup.
pub fn start() Error!void {
    try errors.check(ffi.devserverStart());
}

pub fn stop() Error!void {
    try errors.check(ffi.devserverStop());
}

pub fn isRunning() bool {
    return ffi.devserverIsRunning() > 0;
}

pub fn isStarting() bool {
    return ffi.devserverIsStarting() > 0;
}

fn sliceFromRc(rc: i32, buffer: []u8) errors.Error![]const u8 {
    if (rc < 0) return errors.fromCode(rc);
    return buffer[0..@intCast(rc)];
}

pub fn getUrl(buffer: []u8) Error![]const u8 {
    return sliceFromRc(ffi.devserverGetUrl(buffer.ptr, buffer.len), buffer);
}

pub fn getApSsid(buffer: []u8) Error![]const u8 {
    return sliceFromRc(ffi.devserverGetApSsid(buffer.ptr, buffer.len), buffer);
}

pub fn getApPassword(buffer: []u8) Error![]const u8 {
    return sliceFromRc(ffi.devserverGetApPassword(buffer.ptr, buffer.len), buffer);
}

pub fn getLastError(buffer: []u8) Error![]const u8 {
    return sliceFromRc(ffi.devserverGetLastError(buffer.ptr, buffer.len), buffer);
}
