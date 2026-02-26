pub const Rect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    pub fn contains(self: Rect, px: i32, py: i32) bool {
        return px >= self.x and py >= self.y and px < self.x + self.w and py < self.y + self.h;
    }
};

pub const Padding = struct {
    top: i32,
    right: i32,
    bottom: i32,
    left: i32,

    pub fn all(v: i32) Padding {
        return .{ .top = v, .right = v, .bottom = v, .left = v };
    }

    pub fn horizontal(v: i32) Padding {
        return .{ .top = 0, .right = v, .bottom = 0, .left = v };
    }

    pub fn vertical(v: i32) Padding {
        return .{ .top = v, .right = 0, .bottom = v, .left = 0 };
    }

    pub fn only(top: i32, right: i32, bottom: i32, left: i32) Padding {
        return .{ .top = top, .right = right, .bottom = bottom, .left = left };
    }
};
