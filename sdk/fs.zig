const std = @import("std");
const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

pub const FS_READ: i32 = 0o001;
pub const FS_WRITE: i32 = 0o002;
pub const FS_RDWR: i32 = 0o003;
pub const FS_CREATE: i32 = 0o100;
pub const FS_TRUNC: i32 = 0o200;
pub const FS_APPEND: i32 = 0o400;

pub const SEEK_SET: i32 = 0;
pub const SEEK_CUR: i32 = 1;
pub const SEEK_END: i32 = 2;

pub const SD_INFO_SIZE: usize = 18;

pub const SdCardType = enum(u8) {
    Unknown = 0,
    Sdsc = 1,
    Sdhc = 2,
    Mmc = 3,
    Sdio = 4,
};

pub const SdInfo = struct {
    mounted: bool,
    card_type: SdCardType,
    capacity_bytes: u64,
    name: [6]u8,
};

pub const Metadata = struct {
    size: u64,
    is_dir: bool,
};

const STAT_SIZE: usize = 24;

pub fn isMounted() bool {
    return ffi.fsIsMounted() != 0;
}

pub fn mount() Error!void {
    try errors.check(ffi.fsMount());
}

pub fn unmount() Error!void {
    try errors.check(ffi.fsUnmount());
}

pub fn cardInfo() Error!SdInfo {
    var buf: [SD_INFO_SIZE]u8 = undefined;
    try errors.check(ffi.fsCardInfo(&buf, buf.len));

    const mounted = buf[0] != 0;
    const card_type = @as(SdCardType, @enumFromInt(buf[1]));
    const capacity = std.mem.readInt(u64, buf[4..12], .little);
    var name: [6]u8 = undefined;
    std.mem.copyForwards(u8, name[0..], buf[12..18]);

    return SdInfo{
        .mounted = mounted,
        .card_type = card_type,
        .capacity_bytes = capacity,
        .name = name,
    };
}

pub fn metadata(path: [:0]const u8) Error!Metadata {
    var buf: [STAT_SIZE]u8 = undefined;
    const rc = ffi.fsStat(path, &buf, buf.len);
    if (rc < 0) return errors.fromCode(rc);

    const size = std.mem.readInt(u64, buf[0..8], .little);
    const is_dir = buf[8] != 0;
    return Metadata{ .size = size, .is_dir = is_dir };
}

pub fn mtime(path: [:0]const u8) Error!i64 {
    var buf: [STAT_SIZE]u8 = undefined;
    const rc = ffi.fsStat(path, &buf, buf.len);
    if (rc < 0) return errors.fromCode(rc);
    return std.mem.readInt(i64, buf[16..24], .little);
}

pub fn remove(path: [:0]const u8) Error!void {
    try errors.check(ffi.fsRemove(path));
}

pub fn rename(from: [:0]const u8, to: [:0]const u8) Error!void {
    try errors.check(ffi.fsRename(from, to));
}

pub const SeekFrom = union(enum) {
    Start: i32,
    Current: i32,
    End: i32,

    pub fn toArgs(self: SeekFrom) struct { offset: i32, whence: i32 } {
        return switch (self) {
            .Start => |v| .{ .offset = v, .whence = SEEK_SET },
            .Current => |v| .{ .offset = v, .whence = SEEK_CUR },
            .End => |v| .{ .offset = v, .whence = SEEK_END },
        };
    }
};

pub const File = struct {
    handle: i32,

    pub fn open(path: [:0]const u8, flags: i32) Error!File {
        const handle = ffi.fsOpen(path, flags);
        if (handle < 0) return errors.fromCode(handle);
        return File{ .handle = handle };
    }

    pub fn read(self: *File, out: []u8) Error!usize {
        const rc = ffi.fsRead(self.handle, out.ptr, @intCast(out.len));
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    pub fn write(self: *File, data: []const u8) Error!usize {
        const rc = ffi.fsWrite(self.handle, data.ptr, @intCast(data.len));
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    pub fn seek(self: *File, pos: SeekFrom) Error!i32 {
        const args = pos.toArgs();
        const rc = ffi.fsSeek(self.handle, args.offset, args.whence);
        if (rc < 0) return errors.fromCode(rc);
        return rc;
    }

    pub fn close(self: *File) Error!void {
        if (self.handle < 0) return;
        const handle = self.handle;
        self.handle = -1;
        try errors.check(ffi.fsClose(handle));
    }
};

pub const Dir = struct {
    handle: i32,

    pub fn mkdir(path: [:0]const u8) Error!void {
        try errors.check(ffi.fsMkdir(path));
    }

    pub fn rmdir(path: [:0]const u8) Error!void {
        try errors.check(ffi.fsRmdir(path));
    }

    pub fn open(path: [:0]const u8) Error!Dir {
        const handle = ffi.fsOpendir(path);
        if (handle < 0) return errors.fromCode(handle);
        return Dir{ .handle = handle };
    }

    pub fn readName(self: *Dir, out: []u8) Error!?usize {
        if (out.len == 0) return Error.InvalidArgument;
        const rc = ffi.fsReaddir(self.handle, out.ptr, @intCast(out.len));
        if (rc < 0) return errors.fromCode(rc);
        if (rc == 0) return null;
        return @intCast(rc);
    }

    pub fn close(self: *Dir) Error!void {
        if (self.handle < 0) return;
        const handle = self.handle;
        self.handle = -1;
        try errors.check(ffi.fsClosedir(handle));
    }
};
