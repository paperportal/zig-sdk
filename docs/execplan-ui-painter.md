# UI Painter for Layout-Scoped Drawing

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

No `PLANS.md` file was found in this repository. Maintain this document using the rules described in the `exec-plans` skill (`/Users/mika/.config/codex/skills/exec-plans/SKILL.md`): keep it self-contained, prose-first, and outcome-focused.

## Purpose / Big Picture

After this change, an app can create a `sdk.ui.Painter` that represents a rectangular layout region (x, y, width, height) and then draw using local coordinates relative to that region. The Painter’s bounds are used for layout convenience only: there is no clipping/scissoring, and draw calls are allowed to overflow outside the painter area for performance and simplicity.

“See it working” means an app can:

1. Create a root painter that covers the whole display.
2. Derive a padded or centered painter from it.
3. Call `fillRect`, `drawRect`, and `drawText` on those painters and observe content appears where expected (relative to the derived origin).

## Progress

- [x] (2026-02-26) Add `sdk/ui/painter.zig` with `Painter` + geometry helpers.
- [x] (2026-02-26) Add `Padding` to `sdk/ui/types.zig`, and re-export from `sdk/ui.zig`.
- [x] (2026-02-26) Implement `Painter.fillRect`, `Painter.drawRect`, `Painter.drawText` (no clipping, only origin translation).
- [x] (2026-02-26) Add unit tests for geometry/derivation (no display host calls).
- [x] (2026-02-26) Update `docs/ui-module-programming-guide.md` with a Painter section + example.
- [x] (2026-02-26) Run `zig fmt .`, `zig build`, and `zig test sdk/ui/painter.zig`.

## Surprises & Discoveries

- Observation: `zig test sdk/ui/painter.zig` treats `sdk/ui` as the module root, which means `@import("../display.zig")` fails with “import of file outside module path”.
  Evidence: `sdk/ui/painter.zig:... error: import of file outside module path`

## Decision Log

- Decision: Painter bounds affect layout only; there is no clipping. Draw calls may overflow the painter region.
  Rationale: Keep implementation simple and fast; avoid scissor math and host-level clipping requirements.
  Date/Author: 2026-02-26 / user

- Decision: Negative width/height produce an “empty painter” (width/height become 0). Other invalid size results (e.g. padding that would invert a region) clamp to empty. Both cases log a warning.
  Rationale: Defensive behavior that avoids host errors and keeps call sites simple.
  Date/Author: 2026-02-26 / user

- Decision: Implement Painter’s host-backed drawing and screen sizing via minimal local WASM extern bindings (matching `sdk.display` behavior) instead of importing `sdk/display.zig` and `sdk/core.zig`.
  Rationale: Keep `zig test sdk/ui/painter.zig` runnable as a self-contained unit test target without “outside module path” imports, while still providing the same observable behavior in the Paper Portal host.
  Date/Author: 2026-02-26 / codex

- Decision: On non-wasm targets (unit tests), warnings go to `std.log.warn`; on wasm targets, warnings format into a fixed buffer and call the host `portal_log.logWarn` import.
  Rationale: Unit tests run outside the Paper Portal host, so SDK host logging imports are not available; we still want warnings to exist without breaking tests.
  Date/Author: 2026-02-26 / codex

## Outcomes & Retrospective

- Outcome (2026-02-26): Added `sdk.ui.Painter` for layout-scoped drawing with origin translation (no clipping), plus `ui.Padding` and documentation updates. Geometry/derivation is covered by unit tests runnable via `zig test sdk/ui/painter.zig`; `zig build` continues to succeed.

## Context and Orientation

This repository is a Zig SDK for Paper Portal WASM apps.

Key modules relevant to this task:

- `/Users/mika/code/paperportal/zig-sdk/sdk/display.zig` is the display drawing API. It wraps host functions and provides `drawRect`, `fillRect`, and `text.draw(...)`. Its rectangle functions require non-negative widths/heights.
- `/Users/mika/code/paperportal/zig-sdk/sdk/core.zig` provides host logging helpers in `core.log` (not `std.log`). For the Painter module, warnings are emitted via the same `portal_log.logWarn` host import (with the same formatting approach as `core.log.fwarn`) so that `zig test sdk/ui/painter.zig` remains self-contained.
- `/Users/mika/code/paperportal/zig-sdk/sdk/ui.zig` is the public UI entrypoint that re-exports UI helpers.
- `/Users/mika/code/paperportal/zig-sdk/sdk/ui/types.zig` currently defines `ui.Rect { x, y, w, h }`.
- `/Users/mika/code/paperportal/zig-sdk/docs/ui-module-programming-guide.md` documents the UI module; it currently describes the UI stack and uses `sdk.display.*` directly in scene draw methods.

Terminology used in this plan:

- “Painter”: a small value type containing a rectangle. It provides (a) width/height for layout computations and (b) helper methods that translate local coordinates into global display coordinates.
- “Local coordinates”: coordinates relative to the painter’s top-left corner (0,0 is painter origin).
- “Global coordinates”: coordinates in the display coordinate system used by `sdk.display.*`.
- “Empty painter”: a painter with `w == 0` or `h == 0`. It is valid to use; draw operations are either no-ops or behave consistently with “no clipping” (see drawing rules below).

## Plan of Work

Implement `Painter` as a UI convenience wrapper that translates local coordinates to global display coordinates and then performs the corresponding host-backed draw calls (equivalent to calling `sdk.display.*`). The painter does not clip and does not attempt to validate whether a draw operation stays within bounds; it only translates the origin and provides derived painters for common layout patterns.

Because the UI module previously emphasized being “pure Zig”, update the UI guide to clarify that `ui.Painter` is a convenience layer for host-backed drawing (conceptually the same surface as `sdk.display`), and that this is intentional.

### 1) Add a new Painter module

Create a new file:

- `/Users/mika/code/paperportal/zig-sdk/sdk/ui/painter.zig`

It should:

1. Import `std` and `sdk/ui/types.zig`.
2. Define a local `Error` set and minimal error-code helpers matching `/Users/mika/code/paperportal/zig-sdk/sdk/error.zig`.
3. Define minimal `extern "portal_display"` and `extern "portal_log"` bindings required for rectangles, text, and warnings (matching the behavior of `/Users/mika/code/paperportal/zig-sdk/sdk/display.zig` and `/Users/mika/code/paperportal/zig-sdk/sdk/core.zig`).
2. Define `pub const Painter = struct { x: i32, y: i32, w: i32, h: i32, ... }` or store a `ui.Rect`. Prefer `w/h` naming for consistency with `ui.Rect`.
3. Provide constructors and derivation methods (detailed below).
4. Provide drawing methods (detailed below).
5. Include `test` blocks that exercise only pure geometry and derivation logic (no host calls).

### 2) Constructors and invariants

The painter always stores non-negative `w` and `h`. If inputs are invalid, clamp to empty (set `w = 0`, `h = 0`) and log a warning (host `portal_log.logWarn` on wasm32, `std.log.warn` in unit tests).

Required constructors:

1. `pub fn screen() sdk.errors.Error!Painter`
   - Use `sdk.display.width()` and `sdk.display.height()`.
   - If either value is negative (host not ready), return `Error.NotReady` (or `Error.Unknown` if the code does not map cleanly), rather than producing a bogus painter. (This keeps the failure visible and prevents silently drawing at invalid sizes.)
   - Otherwise return `{ x = 0, y = 0, w = width, h = height }`.

2. `pub fn init(x: i32, y: i32, w: i32, h: i32) Painter`
   - If `w < 0` or `h < 0`, log a warning and return empty with the provided origin (or origin 0,0; pick one and document it—recommended: preserve x/y so derived coordinate spaces stay stable for debugging).
   - If `w == 0` or `h == 0`, return empty (no warning).

3. `pub fn fromRect(r: ui.Rect) Painter` delegates to `init`.

Recommended small helpers (non-essential but makes call sites nicer):

- `pub fn rect(self: Painter) ui.Rect`
- `pub fn width(self: Painter) i32` and `pub fn height(self: Painter) i32`
- `pub fn originX(self: Painter) i32` and `pub fn originY(self: Painter) i32`

### 3) Derivation methods (layout helpers)

Keep the initial surface area small but expressive. Implement the following derivations as methods on `Painter`:

1. `pub fn subPainter(self: Painter, x: i32, y: i32, w: i32, h: i32) Painter`
   - Interpret `x/y/w/h` as local-to-self.
   - Compute the child origin in global coordinates: `(self.x + x, self.y + y)`.
   - Clamp child size so it does not exceed the parent bounds in layout terms:
     - The intended behavior is “a derived painter represents a subregion of the parent.”
     - If the requested region would extend beyond the parent, shrink `w/h` to fit.
     - If shrinking would make `w/h` negative, clamp to empty and log a warning (this is the “invalid sizes clamp to empty” case).
   - Note: this is layout clamping only; it does not imply any draw clipping.

2. `pub fn paddedPainter(self: Painter, pad: Padding) Painter`
   - Inset by `pad` and return a derived painter.
   - If padding exceeds available size (producing negative `w/h`), clamp to empty and log a warning.

3. `pub fn centerPainter(self: Painter, w: i32, h: i32) Painter`
   - Return a painter of size `w/h` positioned so it is centered within `self`.
   - Clamp the centered size to not exceed parent size for layout purposes. If `w/h` are negative, clamp to empty and log a warning.

4. `pub fn translatedPainter(self: Painter, dx: i32, dy: i32) Painter`
   - Shifts the origin by `(dx, dy)` without changing `w/h`. This is useful when the caller wants a coordinate system move but doesn’t want layout-derived resizing.
   - This should not log warnings unless it causes negative sizes (it should not).

If needed later (v2), add alignment generalization:

- `alignedPainter(self, w, h, h_align, v_align)` where align enums are `{ left, center, right }` and `{ top, middle, bottom }`.

### 4) Define Padding (minimal)

`Padding` does not exist yet in `sdk/ui/types.zig`. Add it either:

- in `/Users/mika/code/paperportal/zig-sdk/sdk/ui/types.zig` (recommended so other UI code can reuse it), or
- in `/Users/mika/code/paperportal/zig-sdk/sdk/ui/painter.zig` if you want to keep scope extremely tight.

Minimum design:

- `pub const Padding = struct { top: i32, right: i32, bottom: i32, left: i32, ... }`
- Provide constructors:
  - `pub fn all(v: i32) Padding`
  - `pub fn horizontal(v: i32) Padding` (left/right = v)
  - `pub fn vertical(v: i32) Padding` (top/bottom = v)
  - `pub fn only(top: i32, right: i32, bottom: i32, left: i32) Padding`

No restrictions on negative padding in v1; allow it (it’s a deliberate feature: negative padding can expand). Only when it makes derived width/height negative do we clamp-to-empty and warn.

### 5) Drawing methods (no clipping)

Add these methods on `Painter`:

1. `pub fn fillRect(self: Painter, x: i32, y: i32, w: i32, h: i32, color: sdk.display.Color) sdk.display.Error!void`
   - Translate to global and call the host `portal_display.fillRect(self.x + x, self.y + y, w, h, color)` (equivalent to `sdk.display.fillRect(...)`).
   - If `w < 0` or `h < 0`, do not call the host; instead log a warning and return `null` behavior (recommended: no-op returning success, to match “clamp to empty” philosophy). Document this behavior clearly.

2. `pub fn drawRect(self: Painter, x: i32, y: i32, w: i32, h: i32, color: sdk.display.Color) sdk.display.Error!void`
   - Translate to global and call the host `portal_display.drawRect(...)` (equivalent to `sdk.display.drawRect(...)`).
   - If `w < 0` or `h < 0`, log a warning and no-op.

3. `pub fn drawText(self: Painter, text: []const u8, x: i32, y: i32) sdk.display.Error!void`
   - Translate to global and draw text using the same fixed-buffer + NUL-terminated approach as `sdk.display.text.draw(...)`, calling the host `portal_display.drawString(...)` internally.
   - This method does not manage font/size/color; callers configure text state via `sdk.display.text.*` as usual.

The “no clipping” rule means none of the above checks whether the drawn pixels would exceed the painter bounds. Translation only.

### 6) Re-export from `sdk.ui`

Update:

- `/Users/mika/code/paperportal/zig-sdk/sdk/ui.zig`

Add:

- `pub const painter = @import("ui/painter.zig");`
- `pub const Painter = painter.Painter;`

If `Padding` is placed in `types.zig`, also re-export `Padding` from `sdk/ui.zig` for ergonomic access (`sdk.ui.Padding`).

### 7) Tests (pure geometry only)

In `/Users/mika/code/paperportal/zig-sdk/sdk/ui/painter.zig`, add tests for:

- `init` behavior with negative width/height (clamps to empty).
- `paddedPainter` that results in negative width/height clamps to empty.
- `subPainter` clamping behavior when a requested region exceeds parent bounds.
- `centerPainter` placement and clamping.

Do not test logging output (unless a simple pattern already exists elsewhere). Do not invoke `sdk.display` in tests, since unit tests do not run in the Paper Portal host environment.

### 8) Documentation update

Update:

- `/Users/mika/code/paperportal/zig-sdk/docs/ui-module-programming-guide.md`

Add a new section “Painter” that:

- Explains what a Painter is in plain language (layout-only bounds, no clipping).
- Shows a tiny snippet creating a screen painter, padding it, drawing a background rect, and drawing a text label.
- Mentions that Painter draw methods translate origin and call host-backed display primitives (equivalent to `sdk.display` functions).

## Concrete Steps

All commands run from:

  /Users/mika/code/paperportal/zig-sdk

1. Create `/Users/mika/code/paperportal/zig-sdk/sdk/ui/painter.zig` and wire it into `/Users/mika/code/paperportal/zig-sdk/sdk/ui.zig`.
2. Add `Padding` either to `/Users/mika/code/paperportal/zig-sdk/sdk/ui/types.zig` or to `/Users/mika/code/paperportal/zig-sdk/sdk/ui/painter.zig` and re-export.
3. Add unit tests in `/Users/mika/code/paperportal/zig-sdk/sdk/ui/painter.zig`.
4. Format and validate:

  zig fmt .
  zig build
  zig test sdk/ui/painter.zig

Expected output (representative):

  All 4 tests passed.

## Validation and Acceptance

Acceptance is both API-level and user-visible:

1. Build/test acceptance:
   - `zig build` succeeds.
   - `zig test sdk/ui/painter.zig` succeeds.

2. User-visible acceptance (manual):
   - In any sample app (or a user app), create:
     - `var p = try ui.Painter.screen();`
     - `var content = p.paddedPainter(ui.Padding.all(10));`
     - `try content.fillRect(0, 0, content.width(), content.height(), sdk.display.colors.WHITE);`
     - `try content.drawText("Hello", 0, 0);`
   - Observe that “Hello” appears at 10px inset from the display top-left, and the fill rect origin matches the padded painter origin.
   - Confirm that drawing with coordinates that overflow `content.width()/height()` still renders (no clipping), consistent with design.

## Idempotence and Recovery

These steps are safe to repeat:

- Re-running `zig fmt .`, `zig build`, and `zig test sdk/ui/painter.zig` is idempotent.
- If a step fails, revert local changes or delete the new file(s) and re-apply the plan from the beginning.

## Artifacts and Notes

Logging requirements:

- Emit warnings in a way that works in both environments:
  - On wasm32: format into a fixed buffer and call the host `portal_log.logWarn` import.
  - On non-wasm (unit tests): log via `std.log.warn`.

Use warnings when:
  - `Painter.init(...)` receives negative width/height.
  - A derivation (padding/subPainter/centering) results in negative width/height before clamping.
  - A draw method is called with negative width/height (if you choose to treat this as a no-op instead of forwarding to `sdk.display`).

## Interfaces and Dependencies

At the end of implementation, these names should exist and be importable from the SDK:

- `/Users/mika/code/paperportal/zig-sdk/sdk/ui.zig` exports:
  - `pub const Painter = ...;`
  - `pub const Padding = ...;` (if added)

Minimum required public interface (exact naming can be adjusted to match repo style, but keep functionality):

  pub const Painter = struct {
      x: i32,
      y: i32,
      w: i32,
      h: i32,

      pub fn screen() sdk.errors.Error!Painter;
      pub fn init(x: i32, y: i32, w: i32, h: i32) Painter;
      pub fn fromRect(r: ui.Rect) Painter;

      pub fn width(self: Painter) i32;
      pub fn height(self: Painter) i32;

      pub fn subPainter(self: Painter, x: i32, y: i32, w: i32, h: i32) Painter;
      pub fn paddedPainter(self: Painter, pad: Padding) Painter;
      pub fn centerPainter(self: Painter, w: i32, h: i32) Painter;
      pub fn translatedPainter(self: Painter, dx: i32, dy: i32) Painter;

      pub fn drawRect(self: Painter, x: i32, y: i32, w: i32, h: i32, color: sdk.display.Color) sdk.display.Error!void;
      pub fn fillRect(self: Painter, x: i32, y: i32, w: i32, h: i32, color: sdk.display.Color) sdk.display.Error!void;
      pub fn drawText(self: Painter, text: []const u8, x: i32, y: i32) sdk.display.Error!void;
  };

  pub const Padding = struct {
      top: i32,
      right: i32,
      bottom: i32,
      left: i32,

      pub fn all(v: i32) Padding;
      pub fn horizontal(v: i32) Padding;
      pub fn vertical(v: i32) Padding;
      pub fn only(top: i32, right: i32, bottom: i32, left: i32) Padding;
  };

## Plan Revisions

(2026-02-26) Updated the plan to reflect Zig module-path constraints for `zig test sdk/ui/painter.zig` and the resulting implementation choice to keep the painter module self-contained (local error helpers + minimal extern bindings).
