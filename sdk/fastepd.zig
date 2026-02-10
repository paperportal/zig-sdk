const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const panel = struct {
    pub const NONE: i32 = 0;
    pub const M5PAPER_S3: i32 = 1;
    pub const EPDIY_V7: i32 = 2;
    pub const INKPLATE6PLUS: i32 = 3;
    pub const INKPLATE5V2: i32 = 4;
    pub const EPDIY_V7_16: i32 = 5;
    pub const V7_RAW: i32 = 6;
    pub const LILYGO_T5PRO: i32 = 7;
    pub const LILYGO_T5P4: i32 = 8;
    pub const TRMNL_X: i32 = 9;
    pub const CUSTOM: i32 = 10;
    pub const VIRTUAL: i32 = 11;

    // Backwards-compatible aliases.
    pub const AUTO: i32 = M5PAPER_S3;
    pub const M5PAPER: i32 = M5PAPER_S3;
};

pub const mode = struct {
    pub const NONE: i32 = 0;
    pub const MONOCHROME: i32 = 1; // 1-bpp (black/white)
    pub const GRAYSCALE_16: i32 = 2; // 4-bpp (16 levels)

    // Legacy alias (FastEPD does not have a 2-bpp/4-level mode).
    pub const GRAYSCALE_4: i32 = MONOCHROME;
};

pub const speed = struct {
    pub const DEFAULT: i32 = 0;
    pub const SLOW: i32 = 10000000;
    pub const MEDIUM: i32 = 20000000;
    pub const FAST: i32 = 40000000;
};

pub const Rect = extern struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
};

fn checkEpdRc(rc: i32) Error!void {
    if (rc == 0) return;
    if (rc < 0) return errors.fromCode(rc);
    return Error.Unknown;
}

pub fn init(panel_type: i32, speed_hz: i32) Error!void {
    try checkEpdRc(ffi.epdInitPanel(panel_type, speed_hz));
}

pub fn initLights(led1: i32, led2: i32) Error!void {
    try errors.check(ffi.epdInitLights(led1, led2));
}

pub fn setBrightness(led1: i32, led2: i32) Error!void {
    try errors.check(ffi.epdSetBrightness(led1, led2));
}

pub fn setMode(new_mode: i32) Error!void {
    try checkEpdRc(ffi.epdSetMode(new_mode));
}

pub fn getMode() i32 {
    return ffi.epdGetMode();
}

pub fn setPanelSizePreset(panel_id: i32) Error!void {
    try checkEpdRc(ffi.epdSetPanelSizePreset(panel_id));
}

pub fn setPanelSize(panel_width: i32, panel_height: i32, flags: i32, vcom_mv: i32) Error!void {
    try checkEpdRc(ffi.epdSetPanelSize(panel_width, panel_height, flags, vcom_mv));
}

pub fn setCustomMatrix(matrix: []const u8) Error!void {
    try checkEpdRc(ffi.epdSetCustomMatrix(matrix.ptr, matrix.len));
}

pub fn width() i32 {
    return ffi.epdWidth();
}

pub fn height() i32 {
    return ffi.epdHeight();
}

pub fn getRotation() i32 {
    return ffi.epdGetRotation();
}

pub fn setRotation(rotation: i32) Error!void {
    try checkEpdRc(ffi.epdSetRotation(rotation));
}

pub fn fillScreen(color: i32) Error!void {
    try errors.check(ffi.epdFillScreen(color));
}

pub fn drawPixel(x: i32, y: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawPixel(x, y, color));
}

pub fn drawPixelFast(x: i32, y: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawPixelFast(x, y, color));
}

pub fn drawLine(x1: i32, y1: i32, x2: i32, y2: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawLine(x1, y1, x2, y2, color));
}

pub fn drawRect(x: i32, y: i32, w: i32, h: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawRect(x, y, w, h, color));
}

pub fn fillRect(x: i32, y: i32, w: i32, h: i32, color: i32) Error!void {
    try errors.check(ffi.epdFillRect(x, y, w, h, color));
}

pub fn drawCircle(x: i32, y: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawCircle(x, y, r, color));
}

pub fn fillCircle(x: i32, y: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epdFillCircle(x, y, r, color));
}

pub fn drawRoundRect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawRoundRect(x, y, w, h, r, color));
}

pub fn fillRoundRect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epdFillRoundRect(x, y, w, h, r, color));
}

pub fn drawTriangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) Error!void {
    try errors.check(ffi.epdDrawTriangle(x0, y0, x1, y1, x2, y2, color));
}

pub fn fillTriangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) Error!void {
    try errors.check(ffi.epdFillTriangle(x0, y0, x1, y1, x2, y2, color));
}

pub const text = struct {
    pub fn setColor(fg: i32, bg: i32) Error!void {
        try errors.check(ffi.epdSetTextColor(fg, bg));
    }

    pub fn setCursor(x: i32, y: i32) Error!void {
        try errors.check(ffi.epdSetCursor(x, y));
    }

    pub fn setFont(font: i32) Error!void {
        try errors.check(ffi.epdSetFont(font));
    }

    pub fn setWrap(wrap: bool) Error!void {
        try errors.check(ffi.epdSetTextWrap(@intFromBool(wrap)));
    }

    pub fn drawCstr(text_cstr: [:0]const u8, x: i32, y: i32) Error!void {
        _ = try errors.checkI32(ffi.epdDrawString(text_cstr, x, y));
    }

    pub fn draw(text_bytes: []const u8, x: i32, y: i32) Error!void {
        var buf: [128]u8 = undefined;
        if (buf.len == 0) return Error.InvalidArgument;
        const max_copy = @min(text_bytes.len, buf.len - 1);
        std.mem.copyForwards(u8, buf[0..max_copy], text_bytes[0..max_copy]);
        buf[max_copy] = 0;
        try drawCstr(buf[0..max_copy :0], x, y);
    }

    pub fn getBox(text_cstr: [:0]const u8) Error!Rect {
        var rect: Rect = .{ .x = 0, .y = 0, .w = 0, .h = 0 };
        const rc = ffi.epdGetStringBox(text_cstr, @as([*]u8, @ptrCast(&rect)), @intCast(@sizeOf(Rect)));
        if (rc < 0) return errors.fromCode(rc);
        if (rc != @sizeOf(Rect)) return Error.Internal;
        return rect;
    }
};

pub fn fullUpdate(clear_mode: i32, keep_on: i32) Error!void {
    try checkEpdRc(ffi.epdFullUpdate(clear_mode, keep_on));
}

pub fn fullUpdateRect(clear_mode: i32, keep_on: i32, x: i32, y: i32, w: i32, h: i32) Error!void {
    try checkEpdRc(ffi.epdFullUpdateRect(clear_mode, keep_on, x, y, w, h));
}

pub fn partialUpdate(keep_on: i32, start_row: i32, end_row: i32) Error!void {
    try checkEpdRc(ffi.epdPartialUpdate(keep_on, start_row, end_row));
}

pub fn smoothUpdate(keep_on: i32, color: i32) Error!void {
    try checkEpdRc(ffi.epdSmoothUpdate(keep_on, color));
}

pub fn clearWhite(keep_on: i32) Error!void {
    try checkEpdRc(ffi.epdClearWhite(keep_on));
}

pub fn clearBlack(keep_on: i32) Error!void {
    try checkEpdRc(ffi.epdClearBlack(keep_on));
}

pub fn backupPlane() Error!void {
    try errors.check(ffi.epdBackupPlane());
}

pub fn invertRect(x: i32, y: i32, w: i32, h: i32) Error!void {
    try errors.check(ffi.epdInvertRect(x, y, w, h));
}

pub fn ioPinMode(pin: i32, pin_mode: i32) Error!void {
    try errors.check(ffi.epdIoPinMode(pin, pin_mode));
}

pub fn ioWrite(pin: i32, value: i32) Error!void {
    try errors.check(ffi.epdIoWrite(pin, value));
}

pub fn ioRead(pin: i32) Error!u8 {
    const rc = ffi.epdIoRead(pin);
    if (rc < 0) return errors.fromCode(rc);
    if (rc > 255) return Error.Unknown;
    return @intCast(rc);
}

pub fn einkPower(on: i32) Error!void {
    try checkEpdRc(ffi.epdEinkPower(on));
}

pub fn loadBmp(data: []const u8, x: i32, y: i32, fg: i32, bg: i32) Error!void {
    try checkEpdRc(ffi.epdLoadBmp(data.ptr, data.len, x, y, fg, bg));
}

pub fn loadG5Image(data: []const u8, x: i32, y: i32, fg: i32, bg: i32, scale: f32) Error!void {
    try checkEpdRc(ffi.epdLoadG5Image(data.ptr, data.len, x, y, fg, bg, scale));
}

pub fn setPasses(partial_passes: i32, full_passes: i32) Error!void {
    try errors.check(ffi.epdSetPasses(partial_passes, full_passes));
}

pub fn deinit() Error!void {
    try errors.check(ffi.epdDeinit());
}
