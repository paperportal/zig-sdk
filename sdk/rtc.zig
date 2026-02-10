const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const DateTime = struct {
    year: i16,
    month: u8,
    day: u8,
    week_day: u8,
    hour: u8,
    minute: u8,
    second: u8,
};

const DATE_TIME_SIZE: usize = 10;

pub fn begin() Error!void {
    try errors.check(ffi.rtcBegin());
}

pub fn isEnabled() bool {
    return ffi.rtcIsEnabled() > 0;
}

pub fn getDatetime() Error!DateTime {
    var buf: [DATE_TIME_SIZE]u8 = undefined;
    try errors.check(ffi.rtcGetDatetime(&buf, buf.len));

    const year = std.mem.readInt(i16, buf[0..2], .little);
    return DateTime{
        .year = year,
        .month = buf[2],
        .day = buf[3],
        .week_day = buf[4],
        .hour = buf[5],
        .minute = buf[6],
        .second = buf[7],
    };
}

pub fn setDatetime(dt: DateTime) Error!void {
    var buf: [DATE_TIME_SIZE]u8 = [_]u8{0} ** DATE_TIME_SIZE;
    std.mem.writeInt(i16, buf[0..2], dt.year, .little);
    buf[2] = dt.month;
    buf[3] = dt.day;
    buf[4] = dt.week_day;
    buf[5] = dt.hour;
    buf[6] = dt.minute;
    buf[7] = dt.second;
    buf[8] = 0;
    buf[9] = 0;
    try errors.check(ffi.rtcSetDatetime(&buf, buf.len));
}

pub fn setTimerIrq(ms: i32) Error!void {
    try errors.check(ffi.rtcSetTimerIrq(ms));
}

pub fn setAlarmIrq(seconds: i32) Error!void {
    try errors.check(ffi.rtcSetAlarmIrq(seconds));
}

pub fn clearIrq() Error!void {
    try errors.check(ffi.rtcClearIrq());
}
