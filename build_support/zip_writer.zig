//! Minimal ZIP writer for `.papp` creation.
//!
//! Constraints enforced:
//! - No encryption
//! - No ZIP64 (u32 sizes/offsets, u16 file count)
//! - Compression methods: store (0) or deflate (8, raw DEFLATE stream)
//! - Stable timestamps (0) for deterministic output

const std = @import("std");

/// Supported ZIP compression methods for `.papp` creation.
pub const ZipCompression = enum { store, deflate };

/// ZIP writing errors raised by this module.
pub const ZipError = error{
    /// The ZIP file would contain more than 65535 entries.
    TooManyFiles,
    /// A file size does not fit within 32-bit ZIP fields.
    FileTooLarge,
    /// An internal offset does not fit within 32-bit ZIP fields.
    OffsetTooLarge,
    /// An entry name does not fit within ZIP u16 length fields.
    NameTooLong,
    /// The central directory would exceed 32-bit size fields.
    CentralDirectoryTooLarge,
};

/// Internal central-directory bookkeeping for an entry already written.
const CentralEntry = struct {
    name: []const u8,
    method: ZipCompression,
    crc32: u32,
    compressed_size: u32,
    uncompressed_size: u32,
    local_header_offset: u32,
};

/// Streaming ZIP writer with `.papp` constraints (no ZIP64/encryption).
pub const ZipWriter = struct {
    allocator: std.mem.Allocator,
    w: *std.Io.Writer,
    offset: u64 = 0,
    entries: std.array_list.Managed(CentralEntry),

    /// Creates a new ZIP writer that streams into `writer`.
    pub fn init(allocator: std.mem.Allocator, writer: *std.Io.Writer) ZipWriter {
        return .{
            .allocator = allocator,
            .w = writer,
            .entries = std.array_list.Managed(CentralEntry).init(allocator),
        };
    }

    /// Frees internal bookkeeping (does not close the underlying writer).
    pub fn deinit(self: *ZipWriter) void {
        self.entries.deinit();
    }

    /// Adds an in-memory entry to the ZIP.
    ///
    /// For `deflate`, the payload is compressed to memory before being written
    /// so we can emit headers with known sizes (no data descriptor).
    pub fn addBytes(self: *ZipWriter, name: []const u8, bytes: []const u8, method: ZipCompression) !void {
        const crc = std.hash.Crc32.hash(bytes);
        const uncomp: u32 = std.math.cast(u32, bytes.len) orelse return error.FileTooLarge;

        const local_off = try self.currentOffsetU32();
        var payload: []const u8 = bytes;
        var comp_size: u32 = 0;

        var tmp: std.Io.Writer.Allocating = undefined;
        if (method == .deflate) {
            tmp = .init(self.allocator);
            defer tmp.deinit();
            var deflate_buf: [std.compress.flate.max_window_len]u8 = undefined;
            var compw = try std.compress.flate.Compress.init(&tmp.writer, deflate_buf[0..], .raw, .default);
            try compw.writer.writeAll(bytes);
            try compw.writer.flush();
            payload = tmp.writer.buffered();
            comp_size = std.math.cast(u32, payload.len) orelse return error.FileTooLarge;
        } else {
            comp_size = uncomp;
        }

        try self.writeLocalHeader(name, method, crc, comp_size, uncomp);
        try self.writeAll(payload);

        try self.addCentral(.{
            .name = name,
            .method = method,
            .crc32 = crc,
            .compressed_size = comp_size,
            .uncompressed_size = uncomp,
            .local_header_offset = local_off,
        });
    }

    /// Adds a file from disk at `abs_or_cwd_path` as the ZIP entry `name`.
    /// For `deflate`, a temp file is created under `tmp_dir_path` (which must be writable).
    pub fn addFileFromDisk(
        self: *ZipWriter,
        io: std.Io,
        name: []const u8,
        abs_or_cwd_path: []const u8,
        method: ZipCompression,
        tmp_dir_path: []const u8,
    ) !void {
        switch (method) {
            .store => try self.addFileStored(io, name, abs_or_cwd_path),
            .deflate => try self.addFileDeflated(io, name, abs_or_cwd_path, tmp_dir_path),
        }
    }

    /// Finalizes the ZIP by writing the central directory and end record.
    pub fn finish(self: *ZipWriter) !void {
        const cd_offset = try self.currentOffsetU32();
        if (self.entries.items.len > std.math.maxInt(u16)) return error.TooManyFiles;

        var cd_size: u32 = 0;
        for (self.entries.items) |e| {
            try self.writeCentralHeader(e);
            try self.writeAll(e.name);
            const inc: usize = 46 + e.name.len;
            cd_size = std.math.add(u32, cd_size, std.math.cast(u32, inc) orelse return error.CentralDirectoryTooLarge) catch
                return error.CentralDirectoryTooLarge;
        }

        try self.writeEndRecord(@intCast(self.entries.items.len), cd_size, cd_offset);
    }

    /// Adds a disk file using store (no compression).
    fn addFileStored(self: *ZipWriter, io: std.Io, name: []const u8, path_any: []const u8) !void {
        // Pass 1: stat + CRC.
        var size: u64 = 0;
        var uncomp: u32 = 0;
        var crc: u32 = 0;
        {
            var file = try openFileAny(io, path_any);
            defer file.close(io);
            const st = try file.stat(io);
            if (st.kind != .file) return error.FileTooLarge;
            size = st.size;
            uncomp = std.math.cast(u32, size) orelse return error.FileTooLarge;

            var crc_state: std.hash.Crc32 = .init();
            var buf: [64 * 1024]u8 = undefined;
            var remaining: u64 = size;
            while (remaining != 0) {
                const want: usize = @intCast(@min(@as(u64, buf.len), remaining));
                const n = try file.readStreaming(io, &.{buf[0..want]});
                if (n == 0) break;
                crc_state.update(buf[0..n]);
                remaining -= n;
            }
            if (remaining != 0) return error.FileTooLarge;
            crc = crc_state.final();
        }

        // Pass 2: stream file bytes into archive.
        var file2 = try openFileAny(io, path_any);
        defer file2.close(io);

        const local_off = try self.currentOffsetU32();
        try self.writeLocalHeader(name, .store, crc, uncomp, uncomp);
        try streamCopy(io, &file2, self, size);

        try self.addCentral(.{
            .name = name,
            .method = .store,
            .crc32 = crc,
            .compressed_size = uncomp,
            .uncompressed_size = uncomp,
            .local_header_offset = local_off,
        });
    }

    /// Adds a disk file using deflate compression.
    ///
    /// This stages compressed bytes into a temp file in order to learn the
    /// compressed size before writing headers.
    fn addFileDeflated(self: *ZipWriter, io: std.Io, name: []const u8, path_any: []const u8, tmp_dir_path: []const u8) !void {
        // Open input for streaming.
        var in_file = try openFileAny(io, path_any);
        defer in_file.close(io);
        const st = try in_file.stat(io);
        if (st.kind != .file) return error.FileTooLarge;
        const uncomp = std.math.cast(u32, st.size) orelse return error.FileTooLarge;

        // Ensure tmp dir exists.
        try std.Io.Dir.cwd().createDirPath(io, tmp_dir_path);

        const tmp_path = try tmpFilePath(self.allocator, tmp_dir_path, name);
        defer self.allocator.free(tmp_path);

        var tmp = try createFileAny(io, tmp_path);
        defer tmp.close(io);
        var tmp_writer_buf: [8 * 1024]u8 = undefined;
        var tmp_writer = tmp.writer(io, tmp_writer_buf[0..]);

        var crc_state: std.hash.Crc32 = .init();
        var deflate_buf: [std.compress.flate.max_window_len]u8 = undefined;
        var compw = try std.compress.flate.Compress.init(&tmp_writer.interface, deflate_buf[0..], .raw, .default);

        var buf: [64 * 1024]u8 = undefined;
        var remaining: u64 = st.size;
        while (remaining != 0) {
            const want: usize = @intCast(@min(@as(u64, buf.len), remaining));
            const n = try in_file.readStreaming(io, &.{buf[0..want]});
            if (n == 0) break;
            crc_state.update(buf[0..n]);
            try compw.writer.writeAll(buf[0..n]);
            remaining -= n;
        }
        if (remaining != 0) return error.FileTooLarge;
        try compw.writer.flush();
        try tmp_writer.interface.flush();
        try tmp.sync(io);

        const crc = crc_state.final();
        const tmp_st = try tmp.stat(io);
        const comp = std.math.cast(u32, tmp_st.size) orelse return error.FileTooLarge;

        // Write local header + compressed payload.
        const local_off = try self.currentOffsetU32();
        try self.writeLocalHeader(name, .deflate, crc, comp, uncomp);

        var tmp_read = try openFileAny(io, tmp_path);
        defer tmp_read.close(io);
        try streamCopy(io, &tmp_read, self, tmp_st.size);

        try self.addCentral(.{
            .name = name,
            .method = .deflate,
            .crc32 = crc,
            .compressed_size = comp,
            .uncompressed_size = uncomp,
            .local_header_offset = local_off,
        });
    }

    /// Adds an entry to the central directory list.
    fn addCentral(self: *ZipWriter, e: CentralEntry) !void {
        if (e.name.len > std.math.maxInt(u16)) return error.NameTooLong;
        if (self.entries.items.len >= std.math.maxInt(u16)) return error.TooManyFiles;
        try self.entries.append(e);
    }

    /// Returns the current output offset as a u32 (rejecting ZIP64).
    fn currentOffsetU32(self: *ZipWriter) !u32 {
        return std.math.cast(u32, self.offset) orelse return error.OffsetTooLarge;
    }

    /// Writes bytes to the underlying writer and advances the tracked offset.
    fn writeAll(self: *ZipWriter, bytes: []const u8) !void {
        try self.w.writeAll(bytes);
        self.offset += bytes.len;
    }

    /// Writes a little-endian u16.
    fn writeU16(self: *ZipWriter, v: u16) !void {
        var b: [2]u8 = undefined;
        std.mem.writeInt(u16, &b, v, .little);
        try self.writeAll(&b);
    }

    /// Writes a little-endian u32.
    fn writeU32(self: *ZipWriter, v: u32) !void {
        var b: [4]u8 = undefined;
        std.mem.writeInt(u32, &b, v, .little);
        try self.writeAll(&b);
    }

    /// Writes a local file header followed by the entry name.
    fn writeLocalHeader(self: *ZipWriter, name: []const u8, method: ZipCompression, crc32: u32, comp: u32, uncomp: u32) !void {
        const name_len = std.math.cast(u16, name.len) orelse return error.NameTooLong;
        // Local file header (30 bytes)
        try self.writeU32(0x04034b50);
        try self.writeU16(20); // version needed
        try self.writeU16(0); // flags
        try self.writeU16(methodId(method));
        try self.writeU16(0); // mod time
        try self.writeU16(0); // mod date
        try self.writeU32(crc32);
        try self.writeU32(comp);
        try self.writeU32(uncomp);
        try self.writeU16(name_len);
        try self.writeU16(0); // extra len
        try self.writeAll(name);
    }

    /// Writes a central directory header for an entry (name bytes written by caller).
    fn writeCentralHeader(self: *ZipWriter, e: CentralEntry) !void {
        const name_len = std.math.cast(u16, e.name.len) orelse return error.NameTooLong;
        // Central directory file header (46 bytes)
        try self.writeU32(0x02014b50);
        try self.writeU16(0); // version made by
        try self.writeU16(20); // version needed
        try self.writeU16(0); // flags
        try self.writeU16(methodId(e.method));
        try self.writeU16(0); // mod time
        try self.writeU16(0); // mod date
        try self.writeU32(e.crc32);
        try self.writeU32(e.compressed_size);
        try self.writeU32(e.uncompressed_size);
        try self.writeU16(name_len);
        try self.writeU16(0); // extra len
        try self.writeU16(0); // comment len
        try self.writeU16(0); // disk number
        try self.writeU16(0); // internal attrs
        try self.writeU32(0); // external attrs
        try self.writeU32(e.local_header_offset);
    }

    /// Writes the end-of-central-directory record (no ZIP comment).
    fn writeEndRecord(self: *ZipWriter, count: u16, cd_size: u32, cd_offset: u32) !void {
        // End of central directory record (22 bytes)
        try self.writeU32(0x06054b50);
        try self.writeU16(0); // disk number
        try self.writeU16(0); // cd start disk
        try self.writeU16(count);
        try self.writeU16(count);
        try self.writeU32(cd_size);
        try self.writeU32(cd_offset);
        try self.writeU16(0); // comment len
    }
};

/// Maps `ZipCompression` to ZIP method ids.
fn methodId(m: ZipCompression) u16 {
    return switch (m) {
        .store => 0,
        .deflate => 8,
    };
}

/// Opens a file for reading from either an absolute path or CWD-relative path.
fn openFileAny(io: std.Io, path_any: []const u8) std.Io.File.OpenError!std.Io.File {
    return if (std.fs.path.isAbsolute(path_any))
        std.Io.Dir.openFileAbsolute(io, path_any, .{ .mode = .read_only, .allow_directory = false })
    else
        std.Io.Dir.cwd().openFile(io, path_any, .{ .mode = .read_only, .allow_directory = false });
}

/// Creates/truncates a file for writing at either an absolute path or CWD-relative path.
fn createFileAny(io: std.Io, path_any: []const u8) std.Io.File.OpenError!std.Io.File {
    return if (std.fs.path.isAbsolute(path_any))
        std.Io.Dir.createFileAbsolute(io, path_any, .{ .truncate = true, .read = false })
    else
        std.Io.Dir.cwd().createFile(io, path_any, .{ .truncate = true, .read = false });
}

/// Copies exactly `nbytes` from `in_file` into the ZIP output.
fn streamCopy(io: std.Io, in_file: *std.Io.File, zw: *ZipWriter, nbytes: u64) !void {
    var buf: [64 * 1024]u8 = undefined;
    var remaining: u64 = nbytes;
    while (remaining != 0) {
        const want: usize = @intCast(@min(@as(u64, buf.len), remaining));
        const n = try in_file.readStreaming(io, &.{buf[0..want]});
        if (n == 0) break;
        try zw.writeAll(buf[0..n]);
        remaining -= n;
    }
    if (remaining != 0) return error.EndOfStream;
}

/// Generates a deterministic temp path for deflated payload staging.
fn tmpFilePath(allocator: std.mem.Allocator, tmp_dir_path: []const u8, name: []const u8) ![]u8 {
    var h = std.hash.Wyhash.init(0);
    h.update(name);
    const digest = h.final();
    var hex: [16]u8 = undefined;
    const hex_s = try std.fmt.bufPrint(&hex, "{x:0>16}", .{digest});
    const file_name = try std.fmt.allocPrint(allocator, ".papp-tmp-{s}.bin", .{hex_s});
    defer allocator.free(file_name);
    return std.fs.path.join(allocator, &.{ tmp_dir_path, file_name });
}

test "zip_writer writes basic archive signatures" {
    const a = std.testing.allocator;
    var aw: std.Io.Writer.Allocating = .init(a);
    defer aw.deinit();

    var zw = ZipWriter.init(a, &aw.writer);
    defer zw.deinit();
    try zw.addBytes("manifest.json", "{\"a\":1}", .store);
    try zw.finish();

    const bytes = aw.writer.buffered();
    try std.testing.expect(bytes.len > 22);
    // Local header sig at start
    try std.testing.expectEqual(@as(u8, 'P'), bytes[0]);
    try std.testing.expectEqual(@as(u8, 'K'), bytes[1]);
    // End record sig at end-22
    const end_pos = bytes.len - 22;
    try std.testing.expectEqual(@as(u8, 'P'), bytes[end_pos]);
    try std.testing.expectEqual(@as(u8, 'K'), bytes[end_pos + 1]);
}
