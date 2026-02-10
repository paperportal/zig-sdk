const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const WifiRecord = struct {
    rssi: i32,
    ssid: [33]u8,

    pub fn ssidSlice(self: WifiRecord) []const u8 {
        const nul = std.mem.indexOfScalar(u8, self.ssid[0..], 0) orelse self.ssid.len;
        return self.ssid[0..nul];
    }
};

const WIFI_RECORD_SIZE: usize = 37;

fn parseRecord(buf: [WIFI_RECORD_SIZE]u8) WifiRecord {
    const rssi = std.mem.readInt(i32, buf[0..4], .little);
    var ssid: [33]u8 = undefined;
    std.mem.copyForwards(u8, ssid[0..], buf[4..37]);
    return WifiRecord{ .rssi = rssi, .ssid = ssid };
}

pub fn isReady() bool {
    return ffi.netIsReady() > 0;
}

pub fn connect() Error!void {
    try errors.check(ffi.netConnect());
}

pub fn getIpv4() Error![4]u8 {
    var out: [4]u8 = .{ 0, 0, 0, 0 };
    _ = try errors.checkI32(ffi.netGetIpv4(&out, @intCast(out.len)));
    return out;
}

pub fn disconnect() Error!void {
    try errors.check(ffi.netDisconnect());
}

pub fn wifiScanStart() Error!void {
    try errors.check(ffi.wifiScanStart());
}

pub fn wifiScanIsRunning() bool {
    return ffi.wifiScanIsRunning() > 0;
}

pub fn wifiScanGetCount() Error!i32 {
    return errors.checkI32(ffi.wifiScanGetCount());
}

pub fn wifiScanGetBest() Error!WifiRecord {
    var buf: [WIFI_RECORD_SIZE]u8 = [_]u8{0} ** WIFI_RECORD_SIZE;
    try errors.check(ffi.wifiScanGetBest(&buf, @intCast(buf.len)));
    return parseRecord(buf);
}

pub fn wifiScanGetRecord(index: i32) Error!WifiRecord {
    var buf: [WIFI_RECORD_SIZE]u8 = [_]u8{0} ** WIFI_RECORD_SIZE;
    try errors.check(ffi.wifiScanGetRecord(index, &buf, @intCast(buf.len)));
    return parseRecord(buf);
}
