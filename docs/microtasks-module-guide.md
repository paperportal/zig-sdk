# MicroTasks module guide

This guide documents `sdk.microtask`, the Zig SDK helper for host-scheduled cooperative tasks.

## Quick start

Import the module:

    const sdk = @import("paper_portal_sdk");
    const microtask = sdk.microtask;

Define a stateful task:

    const Worker = struct {
        progress: u32 = 0,

        pub fn step(self: *Worker, now_ms: u32) anyerror!microtask.Action {
            _ = now_ms;
            self.progress += 1;
            if (self.progress >= 100) return microtask.Action.doneNow();
            return microtask.Action.sleepMs(50);
        }
    };

Start and cancel:

    var worker = Worker{};
    const handle = try microtask.start(microtask.Task.from(Worker, &worker), 0, 0);
    try microtask.cancel(handle);

## Action model

`microtask.Action` maps directly to the firmware ABI:

- `doneNow()` -> remove the task.
- `yieldSoon()` -> host reschedules using its default yield delay.
- `sleepMs(ms)` -> host reschedules no earlier than `now + ms`.

`Action.encode()` packs:

- high 32 bits: action kind (`done=0`, `yield=1`, `sleep_ms=2`)
- low 32 bits: argument (`ms` for `sleep_ms`, otherwise `0`)

## Task model

`microtask.Task.from(T, *T)` adapts app state to a type-erased task entry.

Required method on `T`:

- `pub fn step(self: *T, now_ms: u32) anyerror!microtask.Action`

Optional method on `T`:

- `pub fn onCancel(self: *T) void`

The SDK stores tasks in a handle-indexed dispatch table and provides the `portalMicroTaskStep` export from the SDK itself, so apps do not implement that export manually.

## Host interaction wrappers

- `microtask.start(task, start_after_ms, period_ms) -> Error!Handle`
- `microtask.cancel(handle) -> Error!void`
- `microtask.clearAll() -> Error!void`
- `microtask.register(handle, task) -> Error!void` (low-level)
- `microtask.unregister(handle) -> bool` (low-level)
- `microtask.dispatch(handle, now_ms_i32) -> i64` (called by SDK export)
