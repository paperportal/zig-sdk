const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const Feature = struct {
    pub const core: u64 = 1 << 0;
    pub const m5: u64 = 1 << 1;
    pub const display_basics: u64 = 1 << 2;
    pub const display_primitives: u64 = 1 << 3;
    pub const display_text: u64 = 1 << 4;
    pub const display_images: u64 = 1 << 5;
    pub const touch: u64 = 1 << 6;
    pub const fast_epd: u64 = 1 << 7;
    pub const speaker: u64 = 1 << 8;
    pub const rtc: u64 = 1 << 9;
    pub const power: u64 = 1 << 10;
    pub const imu: u64 = 1 << 11;
    pub const net: u64 = 1 << 12;
    pub const http: u64 = 1 << 13;
    pub const httpd: u64 = 1 << 14;
    pub const socket: u64 = 1 << 15;
    pub const fs: u64 = 1 << 16;
    pub const nvs: u64 = 1 << 17;
};

pub fn begin() Error!void {
    try errors.check(ffi.begin());
}

pub fn api_version() i32 {
    return ffi.api_version();
}

pub fn api_features() i64 {
    return ffi.api_features();
}

pub fn last_error_code() i32 {
    return ffi.last_error_code();
}

pub fn last_error_message(buf: []u8) Error![]const u8 {
    if (buf.len == 0) return Error.InvalidArgument;
    try errors.check(ffi.last_error_message(buf.ptr, buf.len));
    const nul_index = std.mem.indexOfScalar(u8, buf, 0) orelse buf.len;
    return buf[0..nul_index];
}

pub fn check_heap_integrity(label: [:0]const u8, print_errors: bool) bool {
    return ffi.check_heap_integrity(label, if (print_errors) 1 else 0) != 0;
}

/// Launch another wasm app. Supported app_ids: "launcher", "settings".
/// arguments is optional JSON data (null or "" for no arguments).
/// Returns Error or void on success.
pub fn open_app(app_id: [:0]const u8, arguments: ?[:0]const u8) Error!void {
    const args = arguments orelse "";
    try errors.check(ffi.open_app(app_id, args));
}

pub const log = struct {
    pub fn info(msg: [:0]const u8) void {
        ffi.log_info(msg);
    }

    pub fn warn(msg: [:0]const u8) void {
        ffi.log_warn(msg);
    }

    pub fn err(msg: [:0]const u8) void {
        ffi.log_error(msg);
    }
};

pub const time = struct {
    pub fn delay_ms(ms: i32) void {
        _ = ffi.delay_ms(ms);
    }

    pub fn millis() i32 {
        return ffi.millis();
    }

    pub fn micros() i64 {
        return ffi.micros();
    }
};
