const builtin = @import("builtin");
const std = @import("std");

const ui = @import("types.zig");

pub const Error = error{
    InvalidArgument,
    Internal,
    NotReady,
    NotFound,
    Unknown,
};

pub const Color = i32;

fn fromCode(code: i32) Error {
    return switch (code) {
        -1 => Error.InvalidArgument,
        -2 => Error.Internal,
        -3 => Error.NotReady,
        -4 => Error.NotFound,
        else => Error.Unknown,
    };
}

fn check(code: i32) Error!void {
    if (code >= 0) return;
    return fromCode(code);
}

fn checkI32(code: i32) Error!i32 {
    if (code >= 0) return code;
    return fromCode(code);
}

const ffi = struct {
    pub extern "portal_display" fn width() i32;
    pub extern "portal_display" fn height() i32;
    pub extern "portal_display" fn drawRect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
    pub extern "portal_display" fn fillRect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
    pub extern "portal_display" fn drawString(text: [*:0]const u8, x: i32, y: i32) i32;
    pub extern "portal_log" fn logWarn(msg: [*:0]const u8) void;
};

fn fwarn(comptime fmt: []const u8, args: anytype) void {
    if (builtin.target.cpu.arch == .wasm32) {
        var buf: [400]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
        ffi.logWarn(msg);
    } else {
        std.log.warn(fmt, args);
    }
}

pub const Painter = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    pub fn screen() Error!Painter {
        const w = ffi.width();
        if (w < 0) return fromCode(w);
        const h = ffi.height();
        if (h < 0) return fromCode(h);

        return .{ .x = 0, .y = 0, .w = w, .h = h };
    }

    pub fn init(x: i32, y: i32, w: i32, h: i32) Painter {
        if (w < 0 or h < 0) {
            fwarn("ui.Painter.init: negative size w={d} h={d}; clamping to empty", .{ w, h });
            return .{ .x = x, .y = y, .w = 0, .h = 0 };
        }
        return .{ .x = x, .y = y, .w = w, .h = h };
    }

    pub fn fromRect(r: ui.Rect) Painter {
        return init(r.x, r.y, r.w, r.h);
    }

    pub fn rect(self: Painter) ui.Rect {
        return .{ .x = self.x, .y = self.y, .w = self.w, .h = self.h };
    }

    pub fn width(self: Painter) i32 {
        return self.w;
    }

    pub fn height(self: Painter) i32 {
        return self.h;
    }

    pub fn originX(self: Painter) i32 {
        return self.x;
    }

    pub fn originY(self: Painter) i32 {
        return self.y;
    }

    pub fn subPainter(self: Painter, x: i32, y: i32, w: i32, h: i32) Painter {
        if (w < 0 or h < 0) {
            fwarn("ui.Painter.subPainter: negative size w={d} h={d}; clamping to empty", .{ w, h });
            return .{ .x = self.x + x, .y = self.y + y, .w = 0, .h = 0 };
        }

        var child_x: i32 = x;
        var child_y: i32 = y;
        var child_w: i32 = w;
        var child_h: i32 = h;

        if (child_x < 0) {
            child_w += child_x;
            child_x = 0;
        }
        if (child_y < 0) {
            child_h += child_y;
            child_y = 0;
        }

        const max_w: i32 = self.w - child_x;
        const max_h: i32 = self.h - child_y;

        if (child_w > max_w) child_w = max_w;
        if (child_h > max_h) child_h = max_h;

        if (child_w < 0 or child_h < 0) {
            fwarn("ui.Painter.subPainter: requested region outside parent; clamping to empty (x={d} y={d} w={d} h={d}, parent_w={d} parent_h={d})", .{ x, y, w, h, self.w, self.h });
            return .{ .x = self.x + child_x, .y = self.y + child_y, .w = 0, .h = 0 };
        }

        return .{ .x = self.x + child_x, .y = self.y + child_y, .w = child_w, .h = child_h };
    }

    pub fn paddedPainter(self: Painter, pad: ui.Padding) Painter {
        const child_x = pad.left;
        const child_y = pad.top;
        const child_w = self.w - pad.left - pad.right;
        const child_h = self.h - pad.top - pad.bottom;

        if (child_w < 0 or child_h < 0) {
            fwarn("ui.Painter.paddedPainter: padding produces negative size (w={d} h={d}); clamping to empty", .{ child_w, child_h });
            return .{ .x = self.x + child_x, .y = self.y + child_y, .w = 0, .h = 0 };
        }

        return .{ .x = self.x + child_x, .y = self.y + child_y, .w = child_w, .h = child_h };
    }

    pub fn centerPainter(self: Painter, w: i32, h: i32) Painter {
        if (w < 0 or h < 0) {
            fwarn("ui.Painter.centerPainter: negative size w={d} h={d}; clamping to empty", .{ w, h });
            return .{ .x = self.x, .y = self.y, .w = 0, .h = 0 };
        }

        const child_w: i32 = @min(w, self.w);
        const child_h: i32 = @min(h, self.h);

        const dx: i32 = @divTrunc(self.w - child_w, 2);
        const dy: i32 = @divTrunc(self.h - child_h, 2);
        return .{ .x = self.x + dx, .y = self.y + dy, .w = child_w, .h = child_h };
    }

    pub fn translatedPainter(self: Painter, dx: i32, dy: i32) Painter {
        return .{ .x = self.x + dx, .y = self.y + dy, .w = self.w, .h = self.h };
    }

    pub fn fillRect(self: Painter, x: i32, y: i32, w: i32, h: i32, color: Color) Error!void {
        if (w < 0 or h < 0) {
            fwarn("ui.Painter.fillRect: negative size w={d} h={d}; no-op", .{ w, h });
            return;
        }
        if (w == 0 or h == 0) return;
        try check(ffi.fillRect(self.x + x, self.y + y, w, h, color));
    }

    pub fn drawRect(self: Painter, x: i32, y: i32, w: i32, h: i32, color: Color) Error!void {
        if (w < 0 or h < 0) {
            fwarn("ui.Painter.drawRect: negative size w={d} h={d}; no-op", .{ w, h });
            return;
        }
        if (w == 0 or h == 0) return;
        try check(ffi.drawRect(self.x + x, self.y + y, w, h, color));
    }

    pub fn drawText(self: Painter, text: []const u8, x: i32, y: i32) Error!void {
        var buf: [128]u8 = undefined;
        const max_copy = @min(text.len, buf.len - 1);
        std.mem.copyForwards(u8, buf[0..max_copy], text[0..max_copy]);
        buf[max_copy] = 0;
        _ = try checkI32(ffi.drawString(buf[0..max_copy :0], self.x + x, self.y + y));
    }
};

test "Painter.init: negative width/height clamps to empty" {
    const p1 = Painter.init(10, 20, -1, 5);
    try std.testing.expectEqual(@as(i32, 10), p1.x);
    try std.testing.expectEqual(@as(i32, 20), p1.y);
    try std.testing.expectEqual(@as(i32, 0), p1.w);
    try std.testing.expectEqual(@as(i32, 0), p1.h);

    const p2 = Painter.init(10, 20, 5, -1);
    try std.testing.expectEqual(@as(i32, 0), p2.w);
    try std.testing.expectEqual(@as(i32, 0), p2.h);
}

test "Painter.paddedPainter: negative result clamps to empty" {
    const root = Painter.init(0, 0, 10, 10);
    const child = root.paddedPainter(ui.Padding.only(6, 6, 6, 6));
    try std.testing.expectEqual(@as(i32, 6), child.x);
    try std.testing.expectEqual(@as(i32, 6), child.y);
    try std.testing.expectEqual(@as(i32, 0), child.w);
    try std.testing.expectEqual(@as(i32, 0), child.h);
}

test "Painter.subPainter: clamp to parent bounds" {
    const root = Painter.init(100, 200, 10, 10);
    const child = root.subPainter(2, 3, 20, 20);
    try std.testing.expectEqual(@as(i32, 102), child.x);
    try std.testing.expectEqual(@as(i32, 203), child.y);
    try std.testing.expectEqual(@as(i32, 8), child.w);
    try std.testing.expectEqual(@as(i32, 7), child.h);
}

test "Painter.centerPainter: centers and clamps" {
    const root = Painter.init(10, 20, 11, 9);
    const c1 = root.centerPainter(5, 3);
    try std.testing.expectEqual(@as(i32, 10 + 3), c1.x);
    try std.testing.expectEqual(@as(i32, 20 + 3), c1.y);
    try std.testing.expectEqual(@as(i32, 5), c1.w);
    try std.testing.expectEqual(@as(i32, 3), c1.h);

    const c2 = root.centerPainter(50, 50);
    try std.testing.expectEqual(@as(i32, 10), c2.x);
    try std.testing.expectEqual(@as(i32, 20), c2.y);
    try std.testing.expectEqual(@as(i32, 11), c2.w);
    try std.testing.expectEqual(@as(i32, 9), c2.h);
}
