const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub fn extPortTestStart() Error!void {
    try errors.check(ffi.extPortTestStart());
}
