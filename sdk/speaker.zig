const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub fn begin() Error!void {
    try errors.check(ffi.speaker_begin());
}

pub fn end() Error!void {
    try errors.check(ffi.speaker_end());
}

pub fn is_enabled() bool {
    return ffi.speaker_is_enabled() > 0;
}

pub fn is_running() bool {
    return ffi.speaker_is_running() > 0;
}

pub fn set_volume(volume: u8) Error!void {
    try errors.check(ffi.speaker_set_volume(@intCast(volume)));
}

pub fn get_volume() Error!u8 {
    const v = ffi.speaker_get_volume();
    if (v < 0) return errors.fromCode(v);
    return @intCast(v);
}

pub fn stop() Error!void {
    try errors.check(ffi.speaker_stop());
}

pub fn tone(freq_hz: f32, duration_ms: i32) Error!void {
    try errors.check(ffi.speaker_tone(freq_hz, duration_ms));
}

pub fn beeper_start(freq_hz: f32, beep_count: i32, duration_ms: i32, gap_ms: i32, pause_ms: i32) Error!void {
    try errors.check(ffi.speaker_beeper_start(freq_hz, beep_count, duration_ms, gap_ms, pause_ms));
}

pub fn beeper_stop() Error!void {
    try errors.check(ffi.speaker_beeper_stop());
}
