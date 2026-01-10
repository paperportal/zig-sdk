//! Display drawing, text, and image APIs.
//!
//! This module is a thin Zig wrapper around the firmware's `m5_display` WASM host functions.
//! Most functions return `Error` on failure; a few "getter" style functions return the raw
//! integer result which may be a negative WASM error code.

/// Standard library import.
const std = @import("std");
/// Low-level display FFI bindings.
const ffi = @import("ffi.zig");
/// Shared error helpers for decoding firmware error codes.
const errors = @import("error.zig");

/// Error set used by display functions.
pub const Error = errors.Error;

/// A packed 24-bit color value in `0x00RRGGBB` form.
///
/// The firmware interprets this as an RGB888 color (alpha is ignored).
pub const Color = i32;

/// Pack 8-bit `r`, `g`, and `b` channels into a `Color` (`0x00RRGGBB`).
pub fn rgb888(r: u8, g: u8, b: u8) Color {
    return @as(i32, @intCast((@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b)));
}

/// Pack a 4-bit grayscale value (`0..15`) into a `Color` (`0x00RRGGBB`).
///
/// `0` maps to black and `15` maps to white.
pub fn gray4(v: u4) Color {
    const channel: u8 = @as(u8, @intCast(v)) * 17;
    return rgb888(channel, channel, channel);
}

/// Common RGB888 color constants.
pub const colors = struct {
    /// `0x000000` (RGB888).
    pub const BLACK: Color = rgb888(0, 0, 0);
    /// `0xFFFFFF` (RGB888).
    pub const WHITE: Color = rgb888(255, 255, 255);
    /// `0xFF0000` (RGB888).
    pub const RED: Color = rgb888(255, 0, 0);
    /// `0x00FF00` (RGB888).
    pub const GREEN: Color = rgb888(0, 255, 0);
    /// `0x0000FF` (RGB888).
    pub const BLUE: Color = rgb888(0, 0, 255);
    /// `0xFFFF00` (RGB888).
    pub const YELLOW: Color = rgb888(255, 255, 0);
    /// `0x00FFFF` (RGB888).
    pub const CYAN: Color = rgb888(0, 255, 255);
    /// `0xFF00FF` (RGB888).
    pub const MAGENTA: Color = rgb888(255, 0, 255);
    /// `0xC8C8C8` (RGB888).
    pub const LIGHT_GRAY: Color = rgb888(200, 200, 200);
};

/// Mirror of LovyanGFX `lgfx::color_depth_t` values used by the firmware.
/// For `image.push_image`, pass one of these values as `depth`.
pub const color_depth = struct {
    /// Mask for extracting the "bits per pixel" count.
    pub const bit_mask: i32 = 0x00FF;
    /// Flag indicating that the format uses an RGB888 palette.
    pub const has_palette: i32 = 0x0800;
    /// Flag indicating the format is "non-swapped" (byte order matches the LovyanGFX `*_nonswapped` variants).
    pub const nonswapped: i32 = 0x0100;
    /// Flag used to select alternate interpretations for some bit depths (e.g. grayscale vs rgb332 for 8bpp).
    pub const alternate: i32 = 0x1000;

    /// 1bpp grayscale bitmap.
    pub const grayscale_1bit: i32 = 0x0001;
    /// 2bpp grayscale bitmap.
    pub const grayscale_2bit: i32 = 0x0002;
    /// 4bpp grayscale bitmap.
    pub const grayscale_4bit: i32 = 0x0004;
    /// 8bpp grayscale bitmap.
    pub const grayscale_8bit: i32 = 0x1008;

    /// 1bpp indexed bitmap with an RGB888 palette (2 entries).
    pub const palette_1bit: i32 = 0x0801;
    /// 2bpp indexed bitmap with an RGB888 palette (4 entries).
    pub const palette_2bit: i32 = 0x0802;
    /// 4bpp indexed bitmap with an RGB888 palette (16 entries).
    pub const palette_4bit: i32 = 0x0804;
    /// 8bpp indexed bitmap with an RGB888 palette (256 entries).
    pub const palette_8bit: i32 = 0x0808;

    /// 8bpp RGB332 packed pixels (1 byte per pixel).
    pub const rgb332_1Byte: i32 = 0x0008;
    /// 16bpp RGB565 packed pixels (2 bytes per pixel).
    pub const rgb565_2Byte: i32 = 0x0010;
    /// 24bpp RGB666 packed pixels (3 bytes per pixel).
    pub const rgb666_3Byte: i32 = 0x1018;
    /// 24bpp RGB888 packed pixels (3 bytes per pixel).
    pub const rgb888_3Byte: i32 = 0x0018;
    /// 32bpp ARGB8888 packed pixels (4 bytes per pixel).
    pub const argb8888_4Byte: i32 = 0x0020;

    /// 16bpp RGB565 packed pixels with non-swapped byte order (2 bytes per pixel).
    pub const rgb565_nonswapped: i32 = 0x0110;
    /// 24bpp RGB666 packed pixels with non-swapped byte order (3 bytes per pixel).
    pub const rgb666_nonswapped: i32 = 0x1118;
    /// 24bpp RGB888 packed pixels with non-swapped byte order (3 bytes per pixel).
    pub const rgb888_nonswapped: i32 = 0x0118;
    /// 32bpp ARGB8888 packed pixels with non-swapped byte order (4 bytes per pixel).
    pub const argb8888_nonswapped: i32 = 0x0120;
};

/// Get the display width in pixels.
///
/// Note: this returns the raw firmware result; if the display is not ready, the return value may be a
/// negative WASM error code (e.g. `-3` for `Error.NotReady`).
pub fn width() i32 {
    return ffi.width();
}

/// Get the display height in pixels.
///
/// Note: this returns the raw firmware result; if the display is not ready, the return value may be a
/// negative WASM error code (e.g. `-3` for `Error.NotReady`).
pub fn height() i32 {
    return ffi.height();
}

/// Display rotation controls.
pub const rotation = struct {
    /// Get the current rotation (`0..3`).
    ///
    /// Note: this returns the raw firmware result; if the display is not ready, the return value may be a
    /// negative WASM error code.
    pub fn get() i32 {
        return ffi.get_rotation();
    }

    /// Set the display rotation.
    ///
    /// `rot` must be in the range `0..3`.
    pub fn set(rot: i32) Error!void {
        try errors.check(ffi.set_rotation(rot));
    }
};

/// Display brightness controls.
pub const brightness = struct {
    /// Get the current brightness (`0..255`).
    ///
    /// Note: this returns the raw firmware result; if the display is not ready, the return value may be a
    /// negative WASM error code.
    pub fn get() i32 {
        return ffi.get_brightness();
    }

    /// Set the display brightness.
    ///
    /// `v` must be in the range `0..255`.
    pub fn set(v: i32) Error!void {
        try errors.check(ffi.set_brightness(v));
    }
};

/// Clear the display back buffer.
pub fn clear() Error!void {
    try errors.check(ffi.clear());
}

/// Fill the display back buffer with `color`.
pub fn fill_screen(color: Color) Error!void {
    try errors.check(ffi.fill_screen(color));
}

/// Begin a batch of drawing operations.
///
/// Pair with `end_write()` when done.
pub fn start_write() Error!void {
    try errors.check(ffi.start_write());
}

/// End a batch of drawing operations started with `start_write()`.
pub fn end_write() Error!void {
    try errors.check(ffi.end_write());
}

/// Trigger a display refresh using the current back buffer.
pub fn update() Error!void {
    try errors.check(ffi.display());
}

/// Trigger a display refresh for a rectangular region.
///
/// All arguments must be non-negative, and the rectangle must be fully within the display bounds.
pub fn update_rect(x: i32, y: i32, w: i32, h: i32) Error!void {
    try errors.check(ffi.display_rect(x, y, w, h));
}

/// Block until the last display refresh completes.
///
/// This wrapper intentionally ignores the firmware return code.
pub fn wait_update() void {
    _ = ffi.wait_display();
}

/// E-paper refresh mode controls.
pub const epd = struct {
    /// High-quality refresh mode.
    pub const QUALITY: i32 = 1;
    /// Text-optimized refresh mode.
    pub const TEXT: i32 = 2;
    /// Faster refresh mode.
    pub const FAST: i32 = 3;
    /// Fastest refresh mode.
    pub const FASTEST: i32 = 4;

    /// Set the current EPD refresh mode.
    ///
    /// `mode` must be in the range `1..4` (see the constants in this struct).
    pub fn set_mode(mode: i32) Error!void {
        try errors.check(ffi.set_epd_mode(mode));
    }

    /// Get the current EPD refresh mode (`1..4`).
    ///
    /// Note: this returns the raw firmware result; if the display is not ready, the return value may be a
    /// negative WASM error code.
    pub fn get_mode() i32 {
        return ffi.get_epd_mode();
    }
};

/// Draw a single pixel into the back buffer.
pub fn draw_pixel(x: i32, y: i32, color: Color) Error!void {
    try errors.check(ffi.draw_pixel(x, y, color));
}

/// Draw a rectangle outline into the back buffer.
///
/// `w` and `h` must be non-negative.
pub fn draw_rect(x: i32, y: i32, w: i32, h: i32, color: Color) Error!void {
    try errors.check(ffi.draw_rect(x, y, w, h, color));
}

/// Fill a rectangle in the back buffer.
///
/// `w` and `h` must be non-negative.
pub fn fill_rect(x: i32, y: i32, w: i32, h: i32, color: Color) Error!void {
    try errors.check(ffi.fill_rect(x, y, w, h, color));
}

/// Draw a fast horizontal line into the back buffer.
///
/// `w` must be non-negative.
pub fn draw_fast_hline(x: i32, y: i32, w: i32, color: Color) Error!void {
    try errors.check(ffi.draw_fast_hline(x, y, w, color));
}

/// Draw a line into the back buffer.
pub fn draw_line(x0: i32, y0: i32, x1: i32, y1: i32, color: Color) Error!void {
    try errors.check(ffi.draw_line(x0, y0, x1, y1, color));
}

/// Fill an arc / ring segment.
///
/// This maps to LovyanGFX `fillArc(x, y, r0, r1, angle0, angle1, color)`, where:
/// - `r0` is the outer radius in pixels
/// - `r1` is the inner radius in pixels
/// - `angle0` / `angle1` are degrees (clockwise, with `0` at 3 o'clock)
pub fn fill_arc(x: i32, y: i32, r0: i32, r1: i32, angle0: f32, angle1: f32, color: Color) Error!void {
    try errors.check(ffi.fill_arc(x, y, r0, r1, angle0, angle1, color));
}

/// Text rendering APIs.
///
/// Functions in this namespace configure text state and draw strings using the current font settings.
pub const text = struct {
    /// Text anchor / datum values.
    ///
    /// These values must match the firmware's accepted set.
    pub const Datum = enum(i32) {
        /// Anchor at the top-left of the text bounding box.
        top_left = 0,
        /// Anchor at the top-center of the text bounding box.
        top_center = 1,
        /// Anchor at the top-right of the text bounding box.
        top_right = 2,

        /// Anchor at the middle-left of the text bounding box.
        middle_left = 4,
        /// Anchor at the middle-center of the text bounding box.
        middle_center = 5,
        /// Anchor at the middle-right of the text bounding box.
        middle_right = 6,

        /// Anchor at the bottom-left of the text bounding box.
        bottom_left = 8,
        /// Anchor at the bottom-center of the text bounding box.
        bottom_center = 9,
        /// Anchor at the bottom-right of the text bounding box.
        bottom_right = 10,

        /// Anchor at the baseline-left of the text.
        baseline_left = 16,
        /// Anchor at the baseline-center of the text.
        baseline_center = 17,
        /// Anchor at the baseline-right of the text.
        baseline_right = 18,
    };

    /// Set the text cursor position.
    pub fn set_cursor(x: i32, y: i32) Error!void {
        try errors.check(ffi.set_cursor(x, y));
    }

    /// Set the foreground (`fg`) and optional background (`bg`) text colors.
    ///
    /// If `bg` is `null`, the firmware is instructed to render with no background color.
    pub fn set_color(fg: Color, bg: ?Color) Error!void {
        const bg_value = if (bg) |c| c else 0;
        const use_bg: i32 = if (bg != null) 1 else 0;
        try errors.check(ffi.set_text_color(fg, bg_value, use_bg));
    }

    /// Set the text size scaling factors.
    ///
    /// Both `sx` and `sy` must be greater than `0`.
    pub fn set_size(sx: f32, sy: f32) Error!void {
        try errors.check(ffi.set_text_size(sx, sy));
    }

    /// Set the text datum (anchor point).
    pub fn set_datum(datum: Datum) Error!void {
        try errors.check(ffi.set_text_datum(@intFromEnum(datum)));
    }

    /// Select one of the built-in fonts.
    ///
    /// Valid `font_id` values:
    /// - `0`: `fonts::Font0`
    /// - `1`: `fonts::AsciiFont8x16`
    /// - `2`: `fonts::AsciiFont24x48`
    /// - `3`: `fonts::TomThumb`
    pub fn set_font(font_id: i32) Error!void {
        try errors.check(ffi.set_text_font(font_id));
    }

    /// Enable/disable wrapping in the X and Y directions.
    pub fn set_wrap(wrap_x: bool, wrap_y: bool) Error!void {
        try errors.check(ffi.set_text_wrap(@intFromBool(wrap_x), @intFromBool(wrap_y)));
    }

    /// Enable/disable text scrolling behavior.
    pub fn set_scroll(scroll: bool) Error!void {
        try errors.check(ffi.set_text_scroll(@intFromBool(scroll)));
    }

    /// Convenience helper: enable UTF-8 decoding and disable CP437.
    pub fn set_encoding_utf8() Error!void {
        try errors.check(ffi.set_text_encoding(1, 0));
    }

    /// Convenience helper: enable CP437 decoding and disable UTF-8.
    pub fn set_encoding_cp437() Error!void {
        try errors.check(ffi.set_text_encoding(0, 1));
    }

    /// Configure text encoding switches.
    pub fn set_encoding(utf8: bool, cp437: bool) Error!void {
        try errors.check(ffi.set_text_encoding(@intFromBool(utf8), @intFromBool(cp437)));
    }

    /// Draw a NUL-terminated string at (`x`, `y`).
    ///
    /// The firmware returns the rendered width, but this wrapper discards it.
    pub fn draw_cstr(text_cstr: [:0]const u8, x: i32, y: i32) Error!void {
        _ = try errors.checkI32(ffi.draw_string(text_cstr, x, y));
    }

    /// Measure the width (in pixels) of a NUL-terminated string using the current font settings.
    pub fn text_width(text_cstr: [:0]const u8) Error!i32 {
        return errors.checkI32(ffi.text_width(text_cstr));
    }

    /// Get the current font height (in pixels).
    ///
    /// Note: this returns the raw firmware result; if the display is not ready, the return value may be a
    /// negative WASM error code.
    pub fn font_height() i32 {
        return ffi.font_height();
    }

    /// Draw a byte slice as text at (`x`, `y`).
    ///
    /// The slice is copied into a fixed 128-byte buffer, NUL-terminated, and truncated to at most 127 bytes.
    pub fn draw(text_bytes: []const u8, x: i32, y: i32) Error!void {
        var buf: [128]u8 = undefined;
        if (buf.len == 0) return Error.InvalidArgument;
        const max_copy = @min(text_bytes.len, buf.len - 1);
        std.mem.copyForwards(u8, buf[0..max_copy], text_bytes[0..max_copy]);
        buf[max_copy] = 0;
        try draw_cstr(buf[0..max_copy :0], x, y);
    }
};

/// Image drawing APIs.
pub const image = struct {
    /// Decode and draw PNG bytes with the top-left corner at (`x`, `y`).
    ///
    /// `x` and `y` must be non-negative. Empty input is a no-op.
    /// The firmware rejects PNG inputs larger than 1 MiB.
    pub fn draw_png(x: i32, y: i32, png_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_png(png_bytes.ptr, png_bytes.len, x, y));
    }

    /// Push raw pixel data to the display.
    ///
    /// `depth` selects the pixel format (see `display.color_depth.*`).
    /// `palette_rgb888` is required for any format that uses a palette:
    /// - all `<8bpp` formats (including `grayscale_*bit`), and
    /// - `palette_8bit`.
    ///
    /// Palette entries are `0x00RRGGBB` values (one `u32` per entry). The entry count is determined by bit depth
    /// (2, 4, 16, or 256 entries for 1, 2, 4, or 8bpp paletted formats).
    ///
    /// The firmware validates:
    /// - The rectangle is in-bounds and `w`/`h` are non-negative.
    /// - `data.len` matches the expected byte length for `w*h` at the chosen bit depth.
    /// - For 16bpp and 32bpp formats, `data.ptr` must be 2-byte or 4-byte aligned, respectively.
    /// - When a palette is required, `palette_rgb888` must have the exact entry count and be 4-byte aligned.
    pub fn push_image(
        x: i32,
        y: i32,
        w: i32,
        h: i32,
        depth: i32,
        data: []const u8,
        palette_rgb888: ?[]const u32,
    ) Error!void {
        const pal_ptr: ?[*]const u8 = if (palette_rgb888) |pal|
            std.mem.sliceAsBytes(pal).ptr
        else
            null;

        const pal_bytes: []const u8 = if (palette_rgb888) |pal| std.mem.sliceAsBytes(pal) else &[_]u8{};
        try errors.check(ffi.push_image(x, y, w, h, data.ptr, data.len, depth, pal_ptr, pal_bytes.len));
    }

    /// Decode and draw an XTH (XTEINK) image, centered on the display.
    ///
    /// Empty input is a no-op. The firmware rejects inputs larger than 1 MiB.
    pub fn draw_xth_centered(xth_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_xth_centered(xth_bytes.ptr, xth_bytes.len));
    }

    /// Decode and draw an XTG (XTEINK, monochrome 1bpp) image, centered on the display.
    ///
    /// Empty input is a no-op. The firmware rejects inputs larger than 1 MiB.
    pub fn draw_xtg_centered(xtg_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_xtg_centered(xtg_bytes.ptr, xtg_bytes.len));
    }

    /// Decode and draw a JPEG, fitting it within (`max_w`, `max_h`) starting at (`x`, `y`).
    ///
    /// `x`, `y`, `max_w`, and `max_h` must be non-negative. If `jpg_bytes` is empty or `max_w/max_h` are zero,
    /// this is a no-op. The firmware rejects JPEG inputs larger than 1 MiB.
    pub fn draw_jpg_fit(x: i32, y: i32, max_w: i32, max_h: i32, jpg_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_jpg_fit(jpg_bytes.ptr, jpg_bytes.len, x, y, max_w, max_h));
    }

    /// Decode and draw a PNG, fitting it within (`max_w`, `max_h`) starting at (`x`, `y`).
    ///
    /// `x`, `y`, `max_w`, and `max_h` must be non-negative. If `png_bytes` is empty or `max_w/max_h` are zero,
    /// this is a no-op. The firmware rejects PNG inputs larger than 1 MiB.
    pub fn draw_png_fit(x: i32, y: i32, max_w: i32, max_h: i32, png_bytes: []const u8) Error!void {
        try errors.check(ffi.draw_png_fit(png_bytes.ptr, png_bytes.len, x, y, max_w, max_h));
    }

    /// Decode and draw a JPEG from a file path, fitting it within (`max_w`, `max_h`) starting at (`x`, `y`).
    ///
    /// `x`, `y`, `max_w`, and `max_h` must be non-negative. If `max_w` or `max_h` are zero, this is a no-op.
    pub fn draw_jpg_file(path_cstr: [:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) Error!void {
        try errors.check(ffi.draw_jpg_file(path_cstr, x, y, max_w, max_h));
    }

    /// Decode and draw a PNG from a file path, fitting it within (`max_w`, `max_h`) starting at (`x`, `y`).
    ///
    /// `x`, `y`, `max_w`, and `max_h` must be non-negative. If `max_w` or `max_h` are zero, this is a no-op.
    pub fn draw_png_file(path_cstr: [:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) Error!void {
        try errors.check(ffi.draw_png_file(path_cstr, x, y, max_w, max_h));
    }
};

/// Vlw font loading APIs.
///
/// Fonts are registered from bytes (copied into firmware heap) and referenced by a handle.
pub const vlw = struct {
    /// Built-in system VLW fonts accepted by `use_system()`.
    pub const SystemFont = enum(i32) {
        inter = 0,
        montserrat = 1,
    };
    pub const system_font = SystemFont;

    /// Register Vlw font bytes and return a handle that can be used with `use()`.
    ///
    /// The firmware rejects zero-length inputs and inputs larger than 1 MiB.
    pub fn register(font_bytes: []const u8) Error!i32 {
        return errors.checkI32(ffi.vlw_register(font_bytes.ptr, font_bytes.len));
    }

    /// Load a previously registered Vlw font by handle.
    ///
    /// This unloads any currently loaded font before loading the new one.
    pub fn use(handle: i32) Error!void {
        try errors.check(ffi.vlw_use(handle));
    }

    /// Load one of the firmware-provided VLW fonts.
    pub fn use_system(font: SystemFont) Error!void {
        try errors.check(ffi.vlw_use_system(@intFromEnum(font)));
    }

    /// Unload the currently loaded Vlw font (if any).
    pub fn unload() Error!void {
        try errors.check(ffi.vlw_unload());
    }

    /// Unload the current font and free all registered Vlw fonts.
    pub fn clear_all() Error!void {
        try errors.check(ffi.vlw_clear_all());
    }
};
