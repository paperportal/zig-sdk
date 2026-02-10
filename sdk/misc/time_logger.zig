const std = @import("std");
const core = @import("../core.zig");

pub const TimeLogger = struct {
    start_us: i64,
    prefix: []const u8,

    pub fn init(prefix: []const u8) TimeLogger {
        return .{
            .start_us = core.time.micros(),
            .prefix = prefix,
        };
    }

    pub fn info(self: *const TimeLogger, comptime fmt: []const u8, args: anytype) void {
        self.logImpl(.info, fmt, args);
    }

    pub fn warn(self: *const TimeLogger, comptime fmt: []const u8, args: anytype) void {
        self.logImpl(.warn, fmt, args);
    }

    fn logImpl(self: *const TimeLogger, level: enum { info, warn }, comptime fmt: []const u8, args: anytype) void {
        var buf: [320]u8 = undefined;

        const elapsed_us: i64 = core.time.micros() - self.start_us;
        const elapsed_ms: i64 = @divTrunc(elapsed_us, 1000);

        var used: usize = 0;
        const head = std.fmt.bufPrint(buf[used..], "{s} +{}ms ", .{ self.prefix, elapsed_ms }) catch return;
        used += head.len;

        const tail = std.fmt.bufPrint(buf[used..], fmt, args) catch return;
        used += tail.len;

        if (used + 1 > buf.len) return;
        buf[used] = 0;
        const msg_z: [:0]const u8 = buf[0..used :0];

        switch (level) {
            .info => core.log.info(msg_z),
            .warn => core.log.warn(msg_z),
        }
    }
};
