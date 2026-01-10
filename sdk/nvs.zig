const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const NVS_READONLY: i32 = 0;
pub const NVS_READWRITE: i32 = 1;

pub const NVS_TYPE_U8: u32 = 0x01;
pub const NVS_TYPE_I8: u32 = 0x11;
pub const NVS_TYPE_U16: u32 = 0x02;
pub const NVS_TYPE_I16: u32 = 0x12;
pub const NVS_TYPE_U32: u32 = 0x04;
pub const NVS_TYPE_I32: u32 = 0x14;
pub const NVS_TYPE_U64: u32 = 0x08;
pub const NVS_TYPE_I64: u32 = 0x18;
pub const NVS_TYPE_STR: u32 = 0x21;
pub const NVS_TYPE_BLOB: u32 = 0x42;
pub const NVS_TYPE_ANY: u32 = 0xff;

pub const EntryInfo = packed struct {
    namespace_name: [16]u8,
    key: [16]u8,
    type_code: u32,

    pub fn namespace(self: *const EntryInfo) []const u8 {
        return cstrSlice(&self.namespace_name);
    }

    pub fn key_name(self: *const EntryInfo) []const u8 {
        return cstrSlice(&self.key);
    }
};

pub const NvsStats = packed struct {
    used_entries: u32,
    free_entries: u32,
    available_entries: u32,
    total_entries: u32,
    namespace_count: u32,
};

fn cstrSlice(buf: []const u8) []const u8 {
    const nul_index = std.mem.indexOfScalar(u8, buf, 0) orelse buf.len;
    return buf[0..nul_index];
}

pub const Namespace = struct {
    handle: i32,

    pub fn open(namespace_name: [:0]const u8, mode: i32) Error!Namespace {
        const handle = ffi.nvs_open(namespace_name, mode);
        if (handle < 0) return errors.fromCode(handle);
        return Namespace{ .handle = handle };
    }

    pub fn close(self: *Namespace) Error!void {
        if (self.handle < 0) return;
        const handle = self.handle;
        self.handle = -1;
        try errors.check(ffi.nvs_close(handle));
    }

    pub fn commit(self: *const Namespace) Error!void {
        try errors.check(ffi.nvs_commit(self.handle));
    }

    pub fn eraseKey(self: *const Namespace, key: [:0]const u8) Error!void {
        try errors.check(ffi.nvs_erase_key(self.handle, key));
    }

    pub fn eraseAll(self: *const Namespace) Error!void {
        try errors.check(ffi.nvs_erase_all(self.handle));
    }

    pub fn setI8(self: *const Namespace, key: [:0]const u8, value: i8) Error!void {
        try errors.check(ffi.nvs_set_i8(self.handle, key, @intCast(value)));
    }

    pub fn setU8(self: *const Namespace, key: [:0]const u8, value: u8) Error!void {
        try errors.check(ffi.nvs_set_u8(self.handle, key, @intCast(value)));
    }

    pub fn setI16(self: *const Namespace, key: [:0]const u8, value: i16) Error!void {
        try errors.check(ffi.nvs_set_i16(self.handle, key, @intCast(value)));
    }

    pub fn setU16(self: *const Namespace, key: [:0]const u8, value: u16) Error!void {
        try errors.check(ffi.nvs_set_u16(self.handle, key, @intCast(value)));
    }

    pub fn setI32(self: *const Namespace, key: [:0]const u8, value: i32) Error!void {
        try errors.check(ffi.nvs_set_i32(self.handle, key, value));
    }

    pub fn setU32(self: *const Namespace, key: [:0]const u8, value: u32) Error!void {
        if (value > std.math.maxInt(i32)) return Error.InvalidArgument;
        try errors.check(ffi.nvs_set_u32(self.handle, key, @intCast(value)));
    }

    pub fn setI64(self: *const Namespace, key: [:0]const u8, value: i64) Error!void {
        try errors.check(ffi.nvs_set_i64(self.handle, key, value));
    }

    pub fn setU64(self: *const Namespace, key: [:0]const u8, value: u64) Error!void {
        if (value > std.math.maxInt(i64)) return Error.InvalidArgument;
        try errors.check(ffi.nvs_set_u64(self.handle, key, @intCast(value)));
    }

    pub fn setStr(self: *const Namespace, key: [:0]const u8, value: [:0]const u8) Error!void {
        try errors.check(ffi.nvs_set_str(self.handle, key, value));
    }

    pub fn setBlob(self: *const Namespace, key: [:0]const u8, value: []const u8) Error!void {
        try errors.check(ffi.nvs_set_blob(self.handle, key, value.ptr, @intCast(value.len)));
    }

    pub fn getI8(self: *const Namespace, key: [:0]const u8) Error!i8 {
        var buf: [1]u8 = undefined;
        const rc = ffi.nvs_get_i8(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(i8, &buf, .little);
    }

    pub fn getU8(self: *const Namespace, key: [:0]const u8) Error!u8 {
        var buf: [1]u8 = undefined;
        const rc = ffi.nvs_get_u8(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return buf[0];
    }

    pub fn getI16(self: *const Namespace, key: [:0]const u8) Error!i16 {
        var buf: [2]u8 = undefined;
        const rc = ffi.nvs_get_i16(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(i16, &buf, .little);
    }

    pub fn getU16(self: *const Namespace, key: [:0]const u8) Error!u16 {
        var buf: [2]u8 = undefined;
        const rc = ffi.nvs_get_u16(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(u16, &buf, .little);
    }

    pub fn getI32(self: *const Namespace, key: [:0]const u8) Error!i32 {
        var buf: [4]u8 = undefined;
        const rc = ffi.nvs_get_i32(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(i32, &buf, .little);
    }

    pub fn getU32(self: *const Namespace, key: [:0]const u8) Error!u32 {
        var buf: [4]u8 = undefined;
        const rc = ffi.nvs_get_u32(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(u32, &buf, .little);
    }

    pub fn getI64(self: *const Namespace, key: [:0]const u8) Error!i64 {
        var buf: [8]u8 = undefined;
        const rc = ffi.nvs_get_i64(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(i64, &buf, .little);
    }

    pub fn getU64(self: *const Namespace, key: [:0]const u8) Error!u64 {
        var buf: [8]u8 = undefined;
        const rc = ffi.nvs_get_u64(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(u64, &buf, .little);
    }

    pub fn getStr(self: *const Namespace, key: [:0]const u8, out: []u8) Error!usize {
        const rc = ffi.nvs_get_str(self.handle, key, out.ptr, @intCast(out.len));
        if (rc < 0) return errors.fromCode(rc);
        if (rc > out.len) return Error.Internal;
        return @intCast(rc);
    }

    pub fn getStrLen(self: *const Namespace, key: [:0]const u8) Error!usize {
        const null_ptr: [*]u8 = @ptrFromInt(0);
        const rc = ffi.nvs_get_str(self.handle, key, null_ptr, 0);
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    pub fn getBlob(self: *const Namespace, key: [:0]const u8, out: []u8) Error!usize {
        const rc = ffi.nvs_get_blob(self.handle, key, out.ptr, @intCast(out.len));
        if (rc < 0) return errors.fromCode(rc);
        if (rc > out.len) return Error.Internal;
        return @intCast(rc);
    }

    pub fn getBlobLen(self: *const Namespace, key: [:0]const u8) Error!usize {
        const null_ptr: [*]u8 = @ptrFromInt(0);
        const rc = ffi.nvs_get_blob(self.handle, key, null_ptr, 0);
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    pub fn findKey(self: *const Namespace, key: [:0]const u8) Error!?u32 {
        var buf: [4]u8 = undefined;
        const rc = ffi.nvs_find_key(self.handle, key, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc == 0) return null;
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(u32, &buf, .little);
    }

    pub fn usedEntryCount(self: *const Namespace) Error!u32 {
        var buf: [4]u8 = undefined;
        const rc = ffi.nvs_get_used_entry_count(self.handle, &buf, buf.len);
        if (rc < 0) return errors.fromCode(rc);
        if (rc != buf.len) return Error.Internal;
        return std.mem.readInt(u32, &buf, .little);
    }

    pub fn entries(self: *const Namespace, type_code: u32) Error!?EntryIterator {
        return EntryIterator.findInHandle(self.handle, type_code);
    }
};

pub const EntryIterator = struct {
    handle: i32,

    pub fn find(partition_name: [:0]const u8, namespace_name: [:0]const u8, type_code: u32) Error!?EntryIterator {
        const handle = ffi.nvs_entry_find(partition_name, namespace_name, @intCast(type_code));
        if (handle < 0) return errors.fromCode(handle);
        if (handle == 0) return null;
        return EntryIterator{ .handle = handle };
    }

    pub fn findInHandle(handle: i32, type_code: u32) Error!?EntryIterator {
        const iterator_handle = ffi.nvs_entry_find_in_handle(handle, @intCast(type_code));
        if (iterator_handle < 0) return errors.fromCode(iterator_handle);
        if (iterator_handle == 0) return null;
        return EntryIterator{ .handle = iterator_handle };
    }

    pub fn next(self: *EntryIterator, info: *EntryInfo) Error!bool {
        if (self.handle < 0) return false;
        const rc = ffi.nvs_entry_info(self.handle, @as([*]u8, @ptrCast(info)), @intCast(@sizeOf(EntryInfo)));
        if (rc < 0) return errors.fromCode(rc);
        if (rc != @sizeOf(EntryInfo)) return Error.Internal;

        const next_rc = ffi.nvs_entry_next(self.handle);
        if (next_rc < 0) return errors.fromCode(next_rc);
        if (next_rc == 0) {
            self.handle = -1;
        }
        return true;
    }

    pub fn release(self: *EntryIterator) Error!void {
        if (self.handle < 0) return;
        const handle = self.handle;
        self.handle = -1;
        try errors.check(ffi.nvs_release_iterator(handle));
    }
};

pub fn getStats(partition_name: [:0]const u8) Error!NvsStats {
    var buf: [@sizeOf(NvsStats)]u8 = undefined;
    const rc = ffi.nvs_get_stats(partition_name, &buf, buf.len);
    if (rc < 0) return errors.fromCode(rc);
    if (rc != buf.len) return Error.Internal;

    return NvsStats{
        .used_entries = std.mem.readInt(u32, buf[0..4], .little),
        .free_entries = std.mem.readInt(u32, buf[4..8], .little),
        .available_entries = std.mem.readInt(u32, buf[8..12], .little),
        .total_entries = std.mem.readInt(u32, buf[12..16], .little),
        .namespace_count = std.mem.readInt(u32, buf[16..20], .little),
    };
}
