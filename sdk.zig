pub const core = @import("sdk/core.zig");
pub const devserver = @import("sdk/devserver.zig");
pub const display = @import("sdk/display.zig");
pub const errors = @import("sdk/error.zig");
pub const fastepd = @import("sdk/fastepd.zig");
pub const fs = @import("sdk/fs.zig");
pub const gesture = @import("sdk/gesture.zig");
pub const hal = @import("sdk/hal.zig");
pub const imu = @import("sdk/imu.zig");
pub const misc = @import("sdk/misc.zig");
pub const net = @import("sdk/net.zig");
pub const nvs = @import("sdk/nvs.zig");
pub const power = @import("sdk/power.zig");
pub const rtc = @import("sdk/rtc.zig");
pub const socket = @import("sdk/socket.zig");
pub const speaker = @import("sdk/speaker.zig");
pub const touch = @import("sdk/touch.zig");
pub const ui = @import("sdk/ui.zig");

pub const Error = errors.Error;

comptime {
    const exports = @import("sdk/internal/exports.zig");
    @export(&exports.portalContractVersion, .{ .name = "portalContractVersion", .linkage = .strong });
    @export(&exports.portalAlloc, .{ .name = "portalAlloc", .linkage = .strong });
    @export(&exports.portalFree, .{ .name = "portalFree", .linkage = .strong });
    //@export(&exports.portal_init, .{ .name = "portal_init", .linkage = .strong });
}
