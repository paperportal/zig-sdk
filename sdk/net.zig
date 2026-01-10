const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const WifiRecord = struct {
    rssi: i32,
    ssid: [33]u8,

    pub fn ssid_slice(self: WifiRecord) []const u8 {
        const nul = std.mem.indexOfScalar(u8, self.ssid[0..], 0) orelse self.ssid.len;
        return self.ssid[0..nul];
    }
};

const WIFI_RECORD_SIZE: usize = 37;

fn parse_record(buf: [WIFI_RECORD_SIZE]u8) WifiRecord {
    const rssi = std.mem.readInt(i32, buf[0..4], .little);
    var ssid: [33]u8 = undefined;
    std.mem.copyForwards(u8, ssid[0..], buf[4..37]);
    return WifiRecord{ .rssi = rssi, .ssid = ssid };
}

pub fn is_ready() bool {
    return ffi.net_is_ready() > 0;
}

pub fn connect() Error!void {
    try errors.check(ffi.net_connect());
}

pub fn get_ipv4() Error![4]u8 {
    var out: [4]u8 = .{ 0, 0, 0, 0 };
    _ = try errors.checkI32(ffi.net_get_ipv4(&out, @intCast(out.len)));
    return out;
}

pub fn disconnect() Error!void {
    try errors.check(ffi.net_disconnect());
}

pub fn wifi_scan_start() Error!void {
    try errors.check(ffi.wifi_scan_start());
}

pub fn wifi_scan_is_running() bool {
    return ffi.wifi_scan_is_running() > 0;
}

pub fn wifi_scan_get_count() Error!i32 {
    return errors.checkI32(ffi.wifi_scan_get_count());
}

pub fn wifi_scan_get_best() Error!WifiRecord {
    var buf: [WIFI_RECORD_SIZE]u8 = [_]u8{0} ** WIFI_RECORD_SIZE;
    try errors.check(ffi.wifi_scan_get_best(&buf, @intCast(buf.len)));
    return parse_record(buf);
}

pub fn wifi_scan_get_record(index: i32) Error!WifiRecord {
    var buf: [WIFI_RECORD_SIZE]u8 = [_]u8{0} ** WIFI_RECORD_SIZE;
    try errors.check(ffi.wifi_scan_get_record(index, &buf, @intCast(buf.len)));
    return parse_record(buf);
}
