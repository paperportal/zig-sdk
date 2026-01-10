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
    try checkEpdRc(ffi.epd_init_panel(panel_type, speed_hz));
}

pub fn init_lights(led1: i32, led2: i32) Error!void {
    try errors.check(ffi.epd_init_lights(led1, led2));
}

pub fn set_brightness(led1: i32, led2: i32) Error!void {
    try errors.check(ffi.epd_set_brightness(led1, led2));
}

pub fn set_mode(new_mode: i32) Error!void {
    try checkEpdRc(ffi.epd_set_mode(new_mode));
}

pub fn get_mode() i32 {
    return ffi.epd_get_mode();
}

pub fn set_panel_size_preset(panel_id: i32) Error!void {
    try checkEpdRc(ffi.epd_set_panel_size_preset(panel_id));
}

pub fn set_panel_size(panel_width: i32, panel_height: i32, flags: i32, vcom_mv: i32) Error!void {
    try checkEpdRc(ffi.epd_set_panel_size(panel_width, panel_height, flags, vcom_mv));
}

pub fn set_custom_matrix(matrix: []const u8) Error!void {
    try checkEpdRc(ffi.epd_set_custom_matrix(matrix.ptr, matrix.len));
}

pub fn width() i32 {
    return ffi.epd_width();
}

pub fn height() i32 {
    return ffi.epd_height();
}

pub fn get_rotation() i32 {
    return ffi.epd_get_rotation();
}

pub fn set_rotation(rotation: i32) Error!void {
    try checkEpdRc(ffi.epd_set_rotation(rotation));
}

pub fn fill_screen(color: i32) Error!void {
    try errors.check(ffi.epd_fill_screen(color));
}

pub fn draw_pixel(x: i32, y: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_pixel(x, y, color));
}

pub fn draw_pixel_fast(x: i32, y: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_pixel_fast(x, y, color));
}

pub fn draw_line(x1: i32, y1: i32, x2: i32, y2: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_line(x1, y1, x2, y2, color));
}

pub fn draw_rect(x: i32, y: i32, w: i32, h: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_rect(x, y, w, h, color));
}

pub fn fill_rect(x: i32, y: i32, w: i32, h: i32, color: i32) Error!void {
    try errors.check(ffi.epd_fill_rect(x, y, w, h, color));
}

pub fn draw_circle(x: i32, y: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_circle(x, y, r, color));
}

pub fn fill_circle(x: i32, y: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epd_fill_circle(x, y, r, color));
}

pub fn draw_round_rect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_round_rect(x, y, w, h, r, color));
}

pub fn fill_round_rect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) Error!void {
    try errors.check(ffi.epd_fill_round_rect(x, y, w, h, r, color));
}

pub fn draw_triangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) Error!void {
    try errors.check(ffi.epd_draw_triangle(x0, y0, x1, y1, x2, y2, color));
}

pub fn fill_triangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) Error!void {
    try errors.check(ffi.epd_fill_triangle(x0, y0, x1, y1, x2, y2, color));
}

pub const text = struct {
    pub fn set_color(fg: i32, bg: i32) Error!void {
        try errors.check(ffi.epd_set_text_color(fg, bg));
    }

    pub fn set_cursor(x: i32, y: i32) Error!void {
        try errors.check(ffi.epd_set_cursor(x, y));
    }

    pub fn set_font(font: i32) Error!void {
        try errors.check(ffi.epd_set_font(font));
    }

    pub fn set_wrap(wrap: bool) Error!void {
        try errors.check(ffi.epd_set_text_wrap(@intFromBool(wrap)));
    }

    pub fn draw_cstr(text_cstr: [:0]const u8, x: i32, y: i32) Error!void {
        _ = try errors.checkI32(ffi.epd_draw_string(text_cstr, x, y));
    }

    pub fn draw(text_bytes: []const u8, x: i32, y: i32) Error!void {
        var buf: [128]u8 = undefined;
        if (buf.len == 0) return Error.InvalidArgument;
        const max_copy = @min(text_bytes.len, buf.len - 1);
        std.mem.copyForwards(u8, buf[0..max_copy], text_bytes[0..max_copy]);
        buf[max_copy] = 0;
        try draw_cstr(buf[0..max_copy :0], x, y);
    }

    pub fn get_box(text_cstr: [:0]const u8) Error!Rect {
        var rect: Rect = .{ .x = 0, .y = 0, .w = 0, .h = 0 };
        const rc = ffi.epd_get_string_box(text_cstr, @as([*]u8, @ptrCast(&rect)), @intCast(@sizeOf(Rect)));
        if (rc < 0) return errors.fromCode(rc);
        if (rc != @sizeOf(Rect)) return Error.Internal;
        return rect;
    }
};

pub fn full_update(clear_mode: i32, keep_on: i32) Error!void {
    try checkEpdRc(ffi.epd_full_update(clear_mode, keep_on));
}

pub fn full_update_rect(clear_mode: i32, keep_on: i32, x: i32, y: i32, w: i32, h: i32) Error!void {
    try checkEpdRc(ffi.epd_full_update_rect(clear_mode, keep_on, x, y, w, h));
}

pub fn partial_update(keep_on: i32, start_row: i32, end_row: i32) Error!void {
    try checkEpdRc(ffi.epd_partial_update(keep_on, start_row, end_row));
}

pub fn smooth_update(keep_on: i32, color: i32) Error!void {
    try checkEpdRc(ffi.epd_smooth_update(keep_on, color));
}

pub fn clear_white(keep_on: i32) Error!void {
    try checkEpdRc(ffi.epd_clear_white(keep_on));
}

pub fn clear_black(keep_on: i32) Error!void {
    try checkEpdRc(ffi.epd_clear_black(keep_on));
}

pub fn backup_plane() Error!void {
    try errors.check(ffi.epd_backup_plane());
}

pub fn invert_rect(x: i32, y: i32, w: i32, h: i32) Error!void {
    try errors.check(ffi.epd_invert_rect(x, y, w, h));
}

pub fn io_pin_mode(pin: i32, pin_mode: i32) Error!void {
    try errors.check(ffi.epd_io_pin_mode(pin, pin_mode));
}

pub fn io_write(pin: i32, value: i32) Error!void {
    try errors.check(ffi.epd_io_write(pin, value));
}

pub fn io_read(pin: i32) Error!u8 {
    const rc = ffi.epd_io_read(pin);
    if (rc < 0) return errors.fromCode(rc);
    if (rc > 255) return Error.Unknown;
    return @intCast(rc);
}

pub fn eink_power(on: i32) Error!void {
    try checkEpdRc(ffi.epd_eink_power(on));
}

pub fn load_bmp(data: []const u8, x: i32, y: i32, fg: i32, bg: i32) Error!void {
    try checkEpdRc(ffi.epd_load_bmp(data.ptr, data.len, x, y, fg, bg));
}

pub fn load_g5_image(data: []const u8, x: i32, y: i32, fg: i32, bg: i32, scale: f32) Error!void {
    try checkEpdRc(ffi.epd_load_g5_image(data.ptr, data.len, x, y, fg, bg, scale));
}

pub fn set_passes(partial_passes: i32, full_passes: i32) Error!void {
    try errors.check(ffi.epd_set_passes(partial_passes, full_passes));
}

pub fn deinit() Error!void {
    try errors.check(ffi.epd_deinit());
}
