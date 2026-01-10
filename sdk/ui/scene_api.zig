const base = @import("scene.zig");
const managed_stack = @import("managed_stack.zig");

pub const Context = base.Context;
pub const GestureKind = base.GestureKind;
pub const GestureEvent = base.GestureEvent;
pub const Scene = base.Scene;
pub const SceneStack = base.SceneStack;
pub const Navigator = base.Navigator;

pub const set = managed_stack.set;
pub const push = managed_stack.push;
pub const replace = managed_stack.replace;
pub const pop = managed_stack.pop;
pub const redraw = managed_stack.redraw;
pub const handleGesture = managed_stack.handleGesture;
pub const handleGestureFromArgs = managed_stack.handleGestureFromArgs;
pub const deinitStack = managed_stack.deinitStack;
