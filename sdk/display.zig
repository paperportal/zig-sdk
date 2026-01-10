const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const Color = i32;

pub fn rgb888(r: u8, g: u8, b: u8) Color {
    return @as(i32, @intCast((@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b)));
}

pub const colors = struct {
    pub const BLACK: Color = rgb888(0, 0, 0);
    pub const WHITE: Color = rgb888(255, 255, 255);
    pub const RED: Color = rgb888(255, 0, 0);
    pub const GREEN: Color = rgb888(0, 255, 0);
    pub const BLUE: Color = rgb888(0, 0, 255);
    pub const YELLOW: Color = rgb888(255, 255, 0);
    pub const CYAN: Color = rgb888(0, 255, 255);
    pub const MAGENTA: Color = rgb888(255, 0, 255);
    pub const LIGHT_GRAY: Color = rgb888(200, 200, 200);
};

pub fn width() i32 {
    return ffi.width();
}

pub fn height() i32 {
    return ffi.height();
}

pub const rotation = struct {
    pub fn get() i32 {
        return ffi.get_rotation();
    }

    pub fn set(rot: i32) Error!void {
        try errors.check(ffi.set_rotation(rot));
    }
};

pub const brightness = struct {
    pub fn get() i32 {
        return ffi.get_brightness();
    }

    pub fn set(v: i32) Error!void {
        try errors.check(ffi.set_brightness(v));
    }
};

pub fn clear() Error!void {
    try errors.check(ffi.clear());
}

pub fn fill_screen(color: Color) Error!void {
    try errors.check(ffi.fill_screen(color));
}

pub fn start_write() Error!void {
    try errors.check(ffi.start_write());
}

pub fn end_write() Error!void {
    try errors.check(ffi.end_write());
}

pub fn update() Error!void {
    try errors.check(ffi.display());
}

pub fn update_rect(x: i32, y: i32, w: i32, h: i32) Error!void {
    try errors.check(ffi.display_rect(x, y, w, h));
}

pub fn wait_update() void {
    _ = ffi.wait_display();
}

pub const epd = struct {
    pub const QUALITY: i32 = 1;
    pub const TEXT: i32 = 2;
    pub const FAST: i32 = 3;
    pub const FASTEST: i32 = 4;

    pub fn set_mode(mode: i32) Error!void {
        try errors.check(ffi.set_epd_mode(mode));
    }

    pub fn get_mode() i32 {
        return ffi.get_epd_mode();
    }
};

pub fn draw_pixel(x: i32, y: i32, color: Color) Error!void {
    try errors.check(ffi.draw_pixel(x, y, color));
}

pub fn draw_rect(x: i32, y: i32, w: i32, h: i32, color: Color) Error!void {
    try errors.check(ffi.draw_rect(x, y, w, h, color));
}

pub fn fill_rect(x: i32, y: i32, w: i32, h: i32, color: Color) Error!void {
    try errors.check(ffi.fill_rect(x, y, w, h, color));
}

pub fn draw_fast_hline(x: i32, y: i32, w: i32, color: Color) Error!void {
    try errors.check(ffi.draw_fast_hline(x, y, w, color));
}

pub fn draw_line(x0: i32, y0: i32, x1: i32, y1: i32, color: Color) Error!void {
    try errors.check(ffi.draw_line(x0, y0, x1, y1, color));
}

pub const text = struct {
    pub const Datum = enum(i32) {
        top_left = 0,
        top_center = 1,
        top_right = 2,

        middle_left = 4,
        middle_center = 5,
        middle_right = 6,

        bottom_left = 8,
        bottom_center = 9,
        bottom_right = 10,

        baseline_left = 16,
        baseline_center = 17,
        baseline_right = 18,
    };

    pub fn set_cursor(x: i32, y: i32) Error!void {
        try errors.check(ffi.set_cursor(x, y));
    }

    pub fn set_color(fg: Color, bg: ?Color) Error!void {
        const bg_value = if (bg) |c| c else 0;
        const use_bg: i32 = if (bg != null) 1 else 0;
        try errors.check(ffi.set_text_color(fg, bg_value, use_bg));
    }

    pub fn set_size(sx: f32, sy: f32) Error!void {
        try errors.check(ffi.set_text_size(sx, sy));
    }

    pub fn set_datum(datum: Datum) Error!void {
        try errors.check(ffi.set_text_datum(@intFromEnum(datum)));
    }

    pub fn set_font(font_id: i32) Error!void {
        try errors.check(ffi.set_text_font(font_id));
    }

    pub fn set_wrap(wrap_x: bool, wrap_y: bool) Error!void {
        try errors.check(ffi.set_text_wrap(@intFromBool(wrap_x), @intFromBool(wrap_y)));
    }

    pub fn set_scroll(scroll: bool) Error!void {
        try errors.check(ffi.set_text_scroll(@intFromBool(scroll)));
    }

    pub fn set_encoding_utf8() Error!void {
        try errors.check(ffi.set_text_encoding(1, 0));
    }

    pub fn set_encoding_cp437() Error!void {
        try errors.check(ffi.set_text_encoding(0, 1));
    }

    pub fn set_encoding(utf8: bool, cp437: bool) Error!void {
        try errors.check(ffi.set_text_encoding(@intFromBool(utf8), @intFromBool(cp437)));
    }

    pub fn draw_cstr(text_cstr: [:0]const u8, x: i32, y: i32) Error!void {
        _ = try errors.checkI32(ffi.draw_string(text_cstr, x, y));
    }

    pub fn text_width(text_cstr: [:0]const u8) Error!i32 {
        return errors.checkI32(ffi.text_width(text_cstr));
    }

    pub fn font_height() i32 {
        return ffi.font_height();
    }

    pub fn draw(text_bytes: []const u8, x: i32, y: i32) Error!void {
        var buf: [128]u8 = undefined;
        if (buf.len == 0) return Error.InvalidArgument;
        const max_copy = @min(text_bytes.len, buf.len - 1);
        std.mem.copyForwards(u8, buf[0..max_copy], text_bytes[0..max_copy]);
        buf[max_copy] = 0;
        try draw_cstr(buf[0..max_copy :0], x, y);
    }
};

pub const image = struct {
    pub fn draw_png(x: i32, y: i32, png_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_png(png_bytes.ptr, png_bytes.len, x, y));
    }

    pub fn draw_jpg_fit(x: i32, y: i32, max_w: i32, max_h: i32, jpg_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_jpg_fit(jpg_bytes.ptr, jpg_bytes.len, x, y, max_w, max_h));
    }

    pub fn draw_png_fit(x: i32, y: i32, max_w: i32, max_h: i32, png_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_png_fit(png_bytes.ptr, png_bytes.len, x, y, max_w, max_h));
    }

    pub fn draw_jpg_file(path_cstr: [:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) Error!void {
        try errors.check(ffi.draw_jpg_file(path_cstr, x, y, max_w, max_h));
    }

    pub fn draw_png_file(path_cstr: [:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) Error!void {
        try errors.check(ffi.draw_png_file(path_cstr, x, y, max_w, max_h));
    }
};

pub const vlw = struct {
    pub fn register(font_bytes: []const u8) Error!i32 {
        return errors.checkI32(ffi.vlw_register(font_bytes.ptr, font_bytes.len));
    }

    pub fn use(handle: i32) Error!void {
        try errors.check(ffi.vlw_use(handle));
    }

    pub fn unload() Error!void {
        try errors.check(ffi.vlw_unload());
    }

    pub fn clear_all() Error!void {
        try errors.check(ffi.vlw_clear_all());
    }
};
