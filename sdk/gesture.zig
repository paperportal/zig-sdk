const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const PointF = extern struct {
    x: f32,
    y: f32,
};

comptime {
    std.debug.assert(@sizeOf(PointF) == 8);
}

pub const Options = packed struct(u32) {
    /// When true (default), the host enforces a "near segment" constraint while tracking.
    segment_constraint_enabled: bool = true,
    _pad: u31 = 0,
};

pub const PolylineParams = struct {
    /// When true, the points are absolute screen coordinates and Down must begin near the first waypoint.
    /// When false, points are treated as relative offsets from the Down position.
    fixed: bool = false,
    tolerance_px: f32 = 16.0,
    priority: i32 = 0,
    /// Maximum duration for recognition in milliseconds. Use 0 for "no limit".
    max_duration_ms: i32 = 0,
    options: Options = .{},
};

pub const GestureKind = enum(i32) {
    tap = 1,
    long_press = 2,
    flick = 3,
    drag_start = 4,
    drag_move = 5,
    drag_end = 6,

    /// Custom polyline gesture recognition result. `flags` carries the winning handle.
    custom_polyline = 100,
};

fn optionsToBits(opts: Options) i32 {
    // Host options bit 0: disable segment constraint when set. Default enabled.
    var bits: u32 = 0;
    if (!opts.segment_constraint_enabled) bits |= 1;
    return @as(i32, @intCast(bits));
}

pub fn clearAll() Error!void {
    try errors.check(ffi.gestureClearAll());
}

pub fn remove(handle: i32) Error!void {
    try errors.check(ffi.gestureRemove(handle));
}

pub fn registerPolyline(id: [:0]const u8, points: []const PointF, params: PolylineParams) Error!i32 {
    if (points.len < 2) return Error.InvalidArgument;
    if (!(params.tolerance_px > 0)) return Error.InvalidArgument;
    if (params.max_duration_ms < 0) return Error.InvalidArgument;

    const bytes = std.mem.sliceAsBytes(points);
    if (bytes.len > std.math.maxInt(i32)) return Error.InvalidArgument;

    const rc = ffi.gestureRegisterPolyline(
        id.ptr,
        bytes.ptr,
        @as(i32, @intCast(bytes.len)),
        if (params.fixed) 1 else 0,
        params.tolerance_px,
        params.priority,
        params.max_duration_ms,
        optionsToBits(params.options),
    );

    return errors.checkI32(rc);
}

/// Interpret `ppOnGesture` args for `GestureKind.custom_polyline`.
pub fn customPolylineHandle(flags: i32) i32 {
    return flags;
}
