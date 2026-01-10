const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub fn begin() Error!void {
    try errors.check(ffi.power_begin());
}

pub fn battery_level_percent() Error!i32 {
    return errors.checkI32(ffi.power_battery_level());
}

pub fn battery_voltage_mv() Error!i32 {
    return errors.checkI32(ffi.power_battery_voltage_mv());
}

pub fn battery_current_ma() Error!i32 {
    return errors.checkI32(ffi.power_battery_current_ma());
}

pub fn is_charging() Error!bool {
    return (try errors.checkI32(ffi.power_is_charging())) != 0;
}

pub fn is_usb_connected() Error!bool {
    return (try errors.checkI32(ffi.power_is_usb_connected())) != 0;
}

pub fn set_battery_charge(enable: bool) Error!void {
    try errors.check(ffi.power_set_battery_charge(@intFromBool(enable)));
}

pub fn restart() Error!void {
    try errors.check(ffi.power_restart());
}

pub fn light_sleep_us(us: i64) Error!void {
    try errors.check(ffi.power_light_sleep_us(us));
}

pub fn deep_sleep_us(us: i64) Error!void {
    try errors.check(ffi.power_deep_sleep_us(us));
}

pub fn off() Error!void {
    try errors.check(ffi.power_off());
}
