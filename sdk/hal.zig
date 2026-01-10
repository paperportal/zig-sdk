const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub fn ext_port_test_start() Error!void {
    try errors.check(ffi.ext_port_test_start());
}
