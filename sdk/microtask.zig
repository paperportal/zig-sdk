const builtin = @import("builtin");
const std = @import("std");
const errors = @import("error.zig");
const ffi = @import("ffi.zig");

pub const Error = errors.Error;
pub const Handle = i32;

pub const ActionKind = enum(u32) {
    done = 0,
    yield = 1,
    sleep_ms = 2,
};

pub const Action = union(ActionKind) {
    done: void,
    yield: void,
    sleep_ms: u32,

    pub fn doneNow() Action {
        return .{ .done = {} };
    }

    pub fn yieldSoon() Action {
        return .{ .yield = {} };
    }

    pub fn sleepMs(ms: u32) Action {
        return .{ .sleep_ms = ms };
    }

    pub fn encode(self: Action) i64 {
        const encoded: u64 = switch (self) {
            .done => (@as(u64, @intFromEnum(ActionKind.done)) << 32),
            .yield => (@as(u64, @intFromEnum(ActionKind.yield)) << 32),
            .sleep_ms => |ms| (@as(u64, @intFromEnum(ActionKind.sleep_ms)) << 32) | @as(u64, ms),
        };
        return @bitCast(encoded);
    }
};

pub const Task = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        step: *const fn (ptr: *anyopaque, now_ms: u32) anyerror!Action,
        onCancel: ?*const fn (ptr: *anyopaque) void = null,
    };

    pub fn from(comptime T: type, task: *T) Task {
        comptime {
            if (!@hasDecl(T, "step")) {
                @compileError("microtask.Task.from(" ++ @typeName(T) ++ "): missing step(self: *T, now_ms: u32) anyerror!microtask.Action");
            }
        }

        const has_onCancel = @hasDecl(T, "onCancel");
        const Gen = struct {
            fn cast(ptr: *anyopaque) *T {
                return @ptrCast(@alignCast(ptr));
            }

            fn step(ptr: *anyopaque, now_ms: u32) anyerror!Action {
                return @call(.auto, T.step, .{ cast(ptr), now_ms });
            }

            fn onCancel(ptr: *anyopaque) void {
                if (comptime !has_onCancel) unreachable;
                @call(.auto, T.onCancel, .{cast(ptr)});
            }

            const vtable = VTable{
                .step = step,
                .onCancel = if (has_onCancel) onCancel else null,
            };
        };

        return .{
            .ptr = task,
            .vtable = &Gen.vtable,
        };
    }
};

const TaskMap = std.AutoHashMapUnmanaged(Handle, Task);

var g_tasks: TaskMap = .{};

fn taskAllocator() std.mem.Allocator {
    if (builtin.target.cpu.arch == .wasm32) {
        return std.heap.wasm_allocator;
    }
    return std.heap.page_allocator;
}

fn clearLocal() void {
    var values = g_tasks.valueIterator();
    while (values.next()) |task| {
        if (task.vtable.onCancel) |f| {
            f(task.ptr);
        }
    }
    g_tasks.clearRetainingCapacity();
}

pub fn register(handle: Handle, task: Task) Error!void {
    if (handle <= 0) return Error.InvalidArgument;
    if (g_tasks.contains(handle)) return Error.InvalidArgument;
    g_tasks.put(taskAllocator(), handle, task) catch return Error.Internal;
}

pub fn unregister(handle: Handle) bool {
    const task = g_tasks.get(handle) orelse return false;
    if (task.vtable.onCancel) |f| {
        f(task.ptr);
    }
    _ = g_tasks.remove(handle);
    return true;
}

pub fn dispatch(handle: Handle, now_ms_i32: i32) i64 {
    if (handle <= 0) return Action.doneNow().encode();

    const task = g_tasks.get(handle) orelse return Action.doneNow().encode();
    const now_ms: u32 = @bitCast(now_ms_i32);
    const action = task.vtable.step(task.ptr, now_ms) catch {
        _ = unregister(handle);
        return Action.doneNow().encode();
    };

    switch (action) {
        .done => {
            _ = unregister(handle);
        },
        else => {},
    }
    return action.encode();
}

pub fn start(task: Task, start_after_ms: u32, period_ms: u32) Error!Handle {
    if (start_after_ms > std.math.maxInt(i32)) return Error.InvalidArgument;
    if (period_ms > std.math.maxInt(i32)) return Error.InvalidArgument;

    const handle = try errors.checkI32(ffi.microtaskStart(
        @intCast(start_after_ms),
        @intCast(period_ms),
        0,
    ));
    if (handle <= 0) {
        return Error.Internal;
    }

    register(handle, task) catch |err| {
        _ = ffi.microtaskCancel(handle);
        return err;
    };
    return handle;
}

pub fn cancel(handle: Handle) Error!void {
    if (handle <= 0) return Error.InvalidArgument;
    _ = unregister(handle);
    try errors.check(ffi.microtaskCancel(handle));
}

pub fn clearAll() Error!void {
    const rc = ffi.microtaskClearAll();
    clearLocal();
    try errors.check(rc);
}

test "Action.encode packs kind and arg" {
    const done_bits: u64 = @bitCast(Action.doneNow().encode());
    try std.testing.expectEqual(@as(u64, 0), done_bits);

    const yield_bits: u64 = @bitCast(Action.yieldSoon().encode());
    try std.testing.expectEqual((@as(u64, 1) << 32), yield_bits);

    const sleep_bits: u64 = @bitCast(Action.sleepMs(250).encode());
    try std.testing.expectEqual((@as(u64, 2) << 32) | @as(u64, 250), sleep_bits);
}

test "register, dispatch, unregister lifecycle" {
    clearLocal();
    defer clearLocal();

    const State = struct {
        calls: u32 = 0,

        pub fn step(self: *@This(), now_ms: u32) anyerror!Action {
            _ = now_ms;
            self.calls += 1;
            return if (self.calls == 1) Action.yieldSoon() else Action.doneNow();
        }
    };

    var state: State = .{};
    try register(101, Task.from(State, &state));

    const first = dispatch(101, 123);
    const first_bits: u64 = @bitCast(first);
    try std.testing.expectEqual((@as(u64, 1) << 32), first_bits);
    try std.testing.expect(g_tasks.contains(101));

    const second = dispatch(101, 124);
    const second_bits: u64 = @bitCast(second);
    try std.testing.expectEqual(@as(u64, 0), second_bits);
    try std.testing.expect(!g_tasks.contains(101));
}

test "unregister runs onCancel callback" {
    clearLocal();
    defer clearLocal();

    const State = struct {
        cancelled: bool = false,

        pub fn step(self: *@This(), now_ms: u32) anyerror!Action {
            _ = self;
            _ = now_ms;
            return Action.yieldSoon();
        }

        pub fn onCancel(self: *@This()) void {
            self.cancelled = true;
        }
    };

    var state: State = .{};
    try register(202, Task.from(State, &state));
    try std.testing.expect(unregister(202));
    try std.testing.expect(state.cancelled);
    try std.testing.expect(!g_tasks.contains(202));
}
