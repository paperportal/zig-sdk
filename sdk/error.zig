const std = @import("std");

pub const Error = error{
    InvalidArgument,
    Internal,
    NotReady,
    NotFound,
    Unknown,
};

pub const Result = Error!void;

pub fn fromCode(code: i32) Error {
    return switch (code) {
        -1 => Error.InvalidArgument,
        -2 => Error.Internal,
        -3 => Error.NotReady,
        -4 => Error.NotFound,
        else => Error.Unknown,
    };
}

pub fn check(code: i32) Error!void {
    if (code >= 0) return;
    return fromCode(code);
}

pub fn checkValue(comptime T: type, code: i32, value: T) Error!T {
    if (code >= 0) return value;
    return fromCode(code);
}

pub fn checkI32(code: i32) Error!i32 {
    if (code >= 0) return code;
    return fromCode(code);
}

pub fn isOk(code: i32) bool {
    return code >= 0;
}

pub fn errorName(err: Error) []const u8 {
    return switch (err) {
        Error.InvalidArgument => "InvalidArgument",
        Error.Internal => "Internal",
        Error.NotReady => "NotReady",
        Error.NotFound => "NotFound",
        Error.Unknown => "Unknown",
    };
}

pub fn writeErrorLabel(buf: []u8, err: Error) [:0]const u8 {
    if (buf.len == 0) return &[_:0]u8{};
    const label = errorName(err);
    const max_copy = @min(label.len, buf.len - 1);
    std.mem.copyForwards(u8, buf[0..max_copy], label[0..max_copy]);
    buf[max_copy] = 0;
    return buf[0..max_copy :0];
}
