const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub fn begin() Error!void {
    try errors.check(ffi.speakerBegin());
}

pub fn end() Error!void {
    try errors.check(ffi.speakerEnd());
}

pub fn isEnabled() bool {
    return ffi.speakerIsEnabled() > 0;
}

pub fn isRunning() bool {
    return ffi.speakerIsRunning() > 0;
}

pub fn setVolume(volume: u8) Error!void {
    try errors.check(ffi.speakerSetVolume(@intCast(volume)));
}

pub fn getVolume() Error!u8 {
    const v = ffi.speakerGetVolume();
    if (v < 0) return errors.fromCode(v);
    return @intCast(v);
}

pub fn stop() Error!void {
    try errors.check(ffi.speakerStop());
}

pub fn tone(freq_hz: f32, duration_ms: i32) Error!void {
    try errors.check(ffi.speakerTone(freq_hz, duration_ms));
}

pub fn beeperStart(freq_hz: f32, beep_count: i32, duration_ms: i32, gap_ms: i32, pause_ms: i32) Error!void {
    try errors.check(ffi.speakerBeeperStart(freq_hz, beep_count, duration_ms, gap_ms, pause_ms));
}

pub fn beeperStop() Error!void {
    try errors.check(ffi.speakerBeeperStop());
}
