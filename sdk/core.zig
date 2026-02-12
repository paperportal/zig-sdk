const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

/// Core SDK error set.
pub const Error = errors.Error;

/// Feature flags returned by `apiFeatures()`.
pub const Feature = struct {
    /// Core API functions are available.
    pub const core: u64 = 1 << 0;
    /// M5-specific APIs are available.
    pub const m5: u64 = 1 << 1;
    /// Basic display APIs are available.
    pub const display_basics: u64 = 1 << 2;
    /// Display primitives (lines, rectangles, etc.) are available.
    pub const display_primitives: u64 = 1 << 3;
    /// Display text APIs are available.
    pub const display_text: u64 = 1 << 4;
    /// Display image APIs are available.
    pub const display_images: u64 = 1 << 5;
    /// Touch APIs are available.
    pub const touch: u64 = 1 << 6;
    /// Fast EPD APIs are available.
    pub const fast_epd: u64 = 1 << 7;
    /// Speaker/audio APIs are available.
    pub const speaker: u64 = 1 << 8;
    /// RTC APIs are available.
    pub const rtc: u64 = 1 << 9;
    /// Power management APIs are available.
    pub const power: u64 = 1 << 10;
    /// IMU sensor APIs are available.
    pub const imu: u64 = 1 << 11;
    /// Networking APIs are available.
    pub const net: u64 = 1 << 12;
    /// HTTP client APIs are available.
    pub const http: u64 = 1 << 13;
    /// HTTP server (httpd) APIs are available.
    pub const httpd: u64 = 1 << 14;
    /// Socket APIs are available.
    pub const socket: u64 = 1 << 15;
    /// Filesystem APIs are available.
    pub const fs: u64 = 1 << 16;
    /// NVS (non-volatile storage) APIs are available.
    pub const nvs: u64 = 1 << 17;
};

/// Display driver selection passed to `begin`.
pub const DisplayDriver = enum(i32) {
    lgfx = 0,
    fastepd = 1,
};

/// Initialize the runtime and bind to the host environment.
pub fn begin(driver: DisplayDriver) Error!void {
    try errors.check(ffi.begin(@intFromEnum(driver)));
}

/// Returns the current host API version number.
pub fn apiVersion() i32 {
    return ffi.apiVersion();
}

/// Returns a bitset of supported API features.
pub fn apiFeatures() i64 {
    return ffi.apiFeatures();
}

/// Returns the last error code reported by the host.
pub fn lastErrorCode() i32 {
    return ffi.lastErrorCode();
}

/// Writes the last error message into `buf` and returns it as a slice (without the trailing NUL).
///
/// `buf` must be non-empty.
pub fn lastErrorMessage(buf: []u8) Error![]const u8 {
    if (buf.len == 0) return Error.InvalidArgument;
    try errors.check(ffi.lastErrorMessage(buf.ptr, buf.len));
    const nul_index = std.mem.indexOfScalar(u8, buf, 0) orelse buf.len;
    return buf[0..nul_index];
}

/// Runs a heap integrity check.
///
/// When `print_errors` is true, the host may emit details to the log.
pub fn heapCheck(label: [:0]const u8, print_errors: bool) bool {
    return ffi.heapCheck(label, if (print_errors) 1 else 0) != 0;
}

/// Logs current heap stats to the host log.
///
/// If `label` is null, uses `"wasm"`.
pub fn heapLog(label: ?[:0]const u8) void {
    ffi.heapLog(label orelse "wasm");
}

/// Launch another wasm app. Supported app_ids: "launcher", "settings".
/// arguments is optional JSON data (null or "" for no arguments).
/// Returns Error or void on success.
pub fn openApp(app_id: [:0]const u8, arguments: ?[:0]const u8) Error!void {
    const args = arguments orelse "";
    try errors.check(ffi.openApp(app_id, args));
}

/// Request exit of the current app. The host relaunches launcher automatically.
pub fn exitApp() Error!void {
    try errors.check(ffi.exitApp());
}

/// Host logging utilities.
pub const log = struct {
    /// Stack buffer size used by the formatted log helpers (`finfo`/`fwarn`/`ferr`).
    pub const format_buf_len: usize = 400;

    /// Logs an informational message.
    pub fn info(msg: [:0]const u8) void {
        ffi.logInfo(msg);
    }

    /// Logs an informational message using a format string and arguments.
    ///
    /// If formatting fails (e.g. message too large for the internal buffer), nothing is logged.
    pub fn finfo(comptime fmt: []const u8, args: anytype) void {
        var buf: [format_buf_len]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
        info(msg);
    }

    /// Logs a warning message.
    pub fn warn(msg: [:0]const u8) void {
        ffi.logWarn(msg);
    }

    /// Logs a warning message using a format string and arguments.
    ///
    /// If formatting fails (e.g. message too large for the internal buffer), nothing is logged.
    pub fn fwarn(comptime fmt: []const u8, args: anytype) void {
        var buf: [format_buf_len]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
        warn(msg);
    }

    /// Logs an error message.
    pub fn err(msg: [:0]const u8) void {
        ffi.logError(msg);
    }

    /// Logs an error message using a format string and arguments.
    ///
    /// If formatting fails (e.g. message too large for the internal buffer), nothing is logged.
    pub fn ferr(comptime fmt: []const u8, args: anytype) void {
        var buf: [format_buf_len]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
        err(msg);
    }
};

/// Time utilities.
pub const time = struct {
    /// Blocks for at least `ms` milliseconds.
    pub fn delayMs(ms: i32) void {
        _ = ffi.delayMs(ms);
    }

    /// Returns milliseconds since boot.
    pub fn millis() i32 {
        return ffi.millis();
    }

    /// Returns microseconds since boot.
    pub fn micros() i64 {
        return ffi.micros();
    }
};
