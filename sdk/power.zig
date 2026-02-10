const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub fn begin() Error!void {
    try errors.check(ffi.powerBegin());
}

pub fn batteryLevelPercent() Error!i32 {
    return errors.checkI32(ffi.powerBatteryLevel());
}

pub fn batteryVoltageMv() Error!i32 {
    return errors.checkI32(ffi.powerBatteryVoltageMv());
}

pub fn batteryCurrentMa() Error!i32 {
    return errors.checkI32(ffi.powerBatteryCurrentMa());
}

pub fn isCharging() Error!bool {
    return (try errors.checkI32(ffi.powerIsCharging())) != 0;
}

pub fn isUsbConnected() Error!bool {
    return (try errors.checkI32(ffi.powerIsUsbConnected())) != 0;
}

pub fn setBatteryCharge(enable: bool) Error!void {
    try errors.check(ffi.powerSetBatteryCharge(@intFromBool(enable)));
}

pub fn restart() Error!void {
    try errors.check(ffi.powerRestart());
}

pub fn lightSleepUs(us: i64) Error!void {
    try errors.check(ffi.powerLightSleepUs(us));
}

pub fn deepSleepUs(us: i64) Error!void {
    try errors.check(ffi.powerDeepSleepUs(us));
}

pub fn off(showSleepImage: bool) Error!void {
    if (showSleepImage) {
        try errors.check(ffi.powerOffWithSleepImage(1));
    } else {
        try errors.check(ffi.powerOff());
    }
}
