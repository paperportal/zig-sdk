const ffi = @import("ffi.zig");
const errors = @import("error.zig");
const socket = @import("socket.zig");

pub const Error = errors.Error;

pub const ServerConfigFlags = struct {
    pub const requireClientCert: i32 = 1 << 0;
};

pub const ServerConfig = struct {
    handle: i32,

    /// Creates a TLS server config from PEM-encoded certificate and private key.
    ///
    /// Notes:
    /// - The host copies the provided PEM bytes during this call.
    /// - `client_ca_pem` is required only when `flags` includes `requireClientCert`.
    pub fn create(server_cert_pem: []const u8, server_key_pem: []const u8, client_ca_pem: ?[]const u8, flags: i32) Error!ServerConfig {
        if (server_cert_pem.len == 0) return Error.InvalidArgument;
        if (server_key_pem.len == 0) return Error.InvalidArgument;

        const ca_ptr: ?[*]const u8 = if (client_ca_pem) |ca| ca.ptr else null;
        const ca_len: usize = if (client_ca_pem) |ca| ca.len else 0;

        const handle = ffi.tlsServerConfigCreate(
            server_cert_pem.ptr,
            server_cert_pem.len,
            server_key_pem.ptr,
            server_key_pem.len,
            ca_ptr,
            ca_len,
            flags,
        );
        if (handle < 0) return errors.fromCode(handle);
        return .{ .handle = handle };
    }

    pub fn deinit(self: *ServerConfig) Error!void {
        if (self.handle <= 0) return;
        const handle = self.handle;
        self.handle = 0;
        try errors.check(ffi.tlsServerConfigFree(handle));
    }
};

pub const TlsSocket = struct {
    handle: i32,

    /// Receives into `out` and returns bytes read.
    pub fn recv(self: *TlsSocket, out: []u8, timeout_ms: i32) Error!usize {
        if (self.handle <= 0) return Error.InvalidArgument;
        if (out.len == 0) return 0;
        const rc = ffi.tlsRecv(self.handle, out.ptr, @intCast(out.len), timeout_ms);
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    /// Sends `data` and returns bytes written.
    pub fn send(self: *TlsSocket, data: []const u8, timeout_ms: i32) Error!usize {
        if (self.handle <= 0) return Error.InvalidArgument;
        if (data.len == 0) return 0;
        const rc = ffi.tlsSend(self.handle, data.ptr, @intCast(data.len), timeout_ms);
        if (rc < 0) return errors.fromCode(rc);
        return @intCast(rc);
    }

    pub fn close(self: *TlsSocket) Error!void {
        if (self.handle <= 0) return;
        const handle = self.handle;
        self.handle = 0;
        try errors.check(ffi.tlsClose(handle));
    }
};

pub const AcceptResult = struct {
    socket: TlsSocket,
    addr: socket.SocketAddr,
};

/// Accepts a new TLS client connection from `listen` (accept + handshake).
///
/// `timeout_ms == 0` performs a non-blocking poll.
/// `timeout_ms > 0` waits up to that duration.
/// `timeout_ms < 0` blocks until a client arrives.
pub fn accept(config: *ServerConfig, listen: *socket.Socket, timeout_ms: i32) Error!AcceptResult {
    if (config.handle <= 0) return Error.InvalidArgument;
    if (listen.fd < 0) return Error.InvalidArgument;

    var addr: socket.SocketAddr = undefined;
    const tls_handle = ffi.tlsAccept(
        config.handle,
        listen.fd,
        @as([*]u8, @ptrCast(&addr)),
        @intCast(@sizeOf(socket.SocketAddr)),
        timeout_ms,
    );
    if (tls_handle < 0) return errors.fromCode(tls_handle);

    return .{ .socket = .{ .handle = tls_handle }, .addr = addr };
}
