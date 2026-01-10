const ffi = @import("ffi.zig");
const errors = @import("error.zig");

pub const Error = errors.Error;

/// Socket domain values (WASM-facing). Note: host implementation is currently IPv4-only.
pub const Domain = enum(i32) {
    inet = 2,
    inet6 = 10,
};

/// Socket type values (WASM-facing).
pub const SocketType = enum(i32) {
    stream = 1,
    dgram = 2,
};

/// Socket address format expected by the host `m5_socket` API.
///
/// Notes:
/// - Host currently treats this as IPv4 even if `family` is inet6.
/// - `port` is in host byte order; the host converts it with `htons()`.
pub const SocketAddr = extern struct {
    family: i32,
    port: u16,
    ip: [4]u8,
    _pad: [2]u8,

    pub fn ipv4(ip: [4]u8, port: u16) SocketAddr {
        return .{
            .family = @intFromEnum(Domain.inet),
            .port = port,
            .ip = ip,
            ._pad = .{ 0, 0 },
        };
    }

    pub fn any(port: u16) SocketAddr {
        return ipv4(.{ 0, 0, 0, 0 }, port);
    }
};

comptime {
    if (@sizeOf(SocketAddr) != 12) @compileError("SocketAddr must be 12 bytes");
    if (@offsetOf(SocketAddr, "family") != 0) @compileError("SocketAddr.family offset must be 0");
    if (@offsetOf(SocketAddr, "port") != 4) @compileError("SocketAddr.port offset must be 4");
    if (@offsetOf(SocketAddr, "ip") != 6) @compileError("SocketAddr.ip offset must be 6");
    if (@offsetOf(SocketAddr, "_pad") != 10) @compileError("SocketAddr._pad offset must be 10");
}

pub const Socket = struct {
    fd: i32,

    pub fn open(domain: Domain, socket_type: SocketType, protocol: i32) Error!Socket {
        const fd = ffi.sock_socket(@intFromEnum(domain), @intFromEnum(socket_type), protocol);
        if (fd < 0) return errors.fromCode(fd);
        return .{ .fd = fd };
    }

    pub fn tcp() Error!Socket {
        return open(.inet, .stream, 0);
    }

    /// Connects the socket to `addr`.
    ///
    /// `timeout_ms` is applied only when `timeout_ms > 0`.
    pub fn connect(self: *Socket, addr: SocketAddr, timeout_ms: i32) Error!void {
        if (self.fd < 0) return Error.InvalidArgument;
        const rc = ffi.sock_connect(
            self.fd,
            @as([*]const u8, @ptrCast(&addr)),
            @intCast(@sizeOf(SocketAddr)),
            timeout_ms,
        );
        try errors.check(rc);
    }

    pub fn bind(self: *Socket, addr: SocketAddr) Error!void {
        if (self.fd < 0) return Error.InvalidArgument;
        const rc = ffi.sock_bind(self.fd, @as([*]const u8, @ptrCast(&addr)), @intCast(@sizeOf(SocketAddr)));
        try errors.check(rc);
    }

    pub fn listen(self: *Socket, backlog: i32) Error!void {
        if (self.fd < 0) return Error.InvalidArgument;
        try errors.check(ffi.sock_listen(self.fd, backlog));
    }

    pub const AcceptResult = struct {
        socket: Socket,
        addr: SocketAddr,
    };

    /// Accepts a new connection.
    ///
    /// This is a blocking call; there is currently no poll/select API exposed.
    pub fn accept(self: *Socket) Error!AcceptResult {
        return self.accept_with_timeout(-1);
    }

    /// Accepts a new connection with timeout control.
    ///
    /// `timeout_ms == 0` performs a non-blocking poll.
    /// `timeout_ms > 0` waits up to that duration.
    /// `timeout_ms < 0` blocks until a client arrives.
    pub fn accept_with_timeout(self: *Socket, timeout_ms: i32) Error!AcceptResult {
        if (self.fd < 0) return Error.InvalidArgument;

        var addr: SocketAddr = undefined;
        const client_fd = ffi.sock_accept_with_timeout(
            self.fd,
            @as([*]u8, @ptrCast(&addr)),
            @intCast(@sizeOf(SocketAddr)),
            timeout_ms,
        );
        if (client_fd < 0) return errors.fromCode(client_fd);

        return .{ .socket = .{ .fd = client_fd }, .addr = addr };
    }

    /// Sends `data` and returns bytes written.
    ///
    /// `timeout_ms` is applied only when `timeout_ms > 0`.
    pub fn send(self: *Socket, data: []const u8, timeout_ms: i32) Error!usize {
        if (self.fd < 0) return Error.InvalidArgument;
        if (data.len == 0) return 0;
        const rc = ffi.sock_send(self.fd, data.ptr, @intCast(data.len), timeout_ms);
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    /// Receives into `out` and returns bytes read.
    ///
    /// `timeout_ms` is applied only when `timeout_ms > 0`.
    pub fn recv(self: *Socket, out: []u8, timeout_ms: i32) Error!usize {
        if (self.fd < 0) return Error.InvalidArgument;
        if (out.len == 0) return 0;
        const rc = ffi.sock_recv(self.fd, out.ptr, @intCast(out.len), timeout_ms);
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    pub fn close(self: *Socket) Error!void {
        if (self.fd < 0) return;
        const fd = self.fd;
        self.fd = -1;
        try errors.check(ffi.sock_close(fd));
    }
};
