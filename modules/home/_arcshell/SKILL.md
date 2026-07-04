# Working in _arcshell

arc-shell is a bespoke Quickshell (Qt6/QML) desktop shell for Hyprland. It is
packaged by `default.nix` (CMake installs `shell.qml` + the four QML dirs into
`share/arc-shell`; a wrapper runs `qs -p` against it) and normally runs as the
`arcshell` systemd user service via `modules/home/programs-arcshell.nix`.

## Layout

```
shell.qml        Entrypoint: ShellRoot { Desktop; Hud }
components/      Reusable leaf widgets (ArcText, ArcWindow, AnimatedNumber, …)
  launcher/      Launcher Wrapper + Content (lives here, not in hud/)
config/          Config singleton, theme config, FileSystem paths
  tokens/        Design tokens (see below)
hud/             Per-screen HUD: Bar, Panels, Drawers, panel subdirs
services/        pragma Singleton state + hardware/IPC services
```

Imports use Quickshell's shell-root-relative modules: `import qs.components`,
`import qs.hud.controlcenter as ControlCenter`, etc. — the path after `qs.` is the directory.
Adding a file to a directory makes it available to that module; there are no
qmldir files to maintain.

## Architecture

### HUD composition (hud/Hud.qml)

One `ArcWindow` (a `PanelWindow` with `WlrLayershell.namespace:
"arc-shell-<name>"`, transparent) per screen via `Variants { model:
Quickshell.screens }`. Inside it:

- `Interactions` wraps `Panels` (the animated panel wrappers) and `Bar`.
- `Drawers` draws the dynamic island's chrome as a `ShapePath` in a `Shape`.
- `HudBorder` + a `Region` mask: the window covers the whole screen but only
  the bar/border/panel rects receive input; panel rects are subtracted
  dynamically from `panels.children`.
- Keyboard: a single `HyprlandFocusGrab` whitelisting every screen's HUD
  window (Hyprland holds one seat grab — per-screen grabs would dismiss each
  other). `WlrLayershell.keyboardFocus` is `OnDemand` while the launcher is
  open, never `Exclusive` (exclusive layers break Hyprland's focus restore on
  close). `onCleared` only fires for compositor-side dismissal (click
  outside), so programmatic closes don't re-enter.

### Panel pattern

Every panel (controlcenter, dynamicisland, notificationcenter, launcher)
is a Wrapper + Content pair:

- **Wrapper.qml** — the state machine. Root `Item` sized by animated
  properties, `states: State { name: "visible"; when: <UiState or service
  condition> }` plus two `Transition`s (open/close) each running one
  `AnimatedNumber`. Never add `from:`/`to:` overrides on the animations: the
  Transition inferring targets from the state is what makes mid-animation
  reversal retrace correctly.
- **Content.qml** — the actual UI, loaded lazily. The launcher uses `Loader {
  Component.onCompleted: active = Qt.binding(() => root.shouldBeActive ||
  root.visible) }` so content exists while animating closed and unloads after.

Chrome: controlcenter, notificationcenter, and launcher draw fading
`BorderLine` items (`components/BorderLine.qml`, tokens =
`BorderLineValues`) inside their Wrappers — lines only on the exposed
edges, whiskers overshooting each corner. The corner panels scale width
AND height off a single `progress` out of their screen corner
(controlcenter: bottom-left; notificationcenter: top-right); the
launcher runs a two-phase CRT sweep (`widthProgress`/`heightProgress`).
Content paints its own background (`Config.theme.hud.border.color`).
Only the dynamic island still has a **Drawer.qml** — a `ShapePath`
registered in `hud/Drawers.qml` drawing rounded chrome sized off its
`wrapper`.

Panel geometry/anchoring lives in `hud/Panels.qml`.

### Services (services/)

`pragma Singleton` throughout. Key ones:

- `UiState` — the `show*` booleans every panel's `when:` reads, plus global
  shortcuts (`WaylandShortcut` = `GlobalShortcut` with `appid:
  "nix-config-shell"`; bound to keys in the Hyprland nix config).
- `Hypr`/`Compositor` — Hyprland glue (`Hypr.monitorFor(screen)`).
- Hardware: `Audio`, `Brightness` (ddcutil/brightnessctl via `Quickshell.Io`
  processes), `Network`, `IdleInhibitor`, `Clock`.
- Launcher search providers: `AppSearch`, `BinSearch`, `ShellSearch`,
  `CalcSearch`, `GlyphSearch` — touched at startup (e.g.
  `Component.onCompleted: GlyphSearch.entries`) so indexes are built before
  first keystroke.

External binaries used by services must be added to `runtimeInputs` in
`default.nix` (they end up on the wrapper's PATH).

### Config & theming (config/)

`Config` is a singleton `FileView` on `${XDG_CONFIG_HOME}/arcshell/shell.json`
with `watchChanges: true` — user settings hot-reload through a `JsonAdapter`
exposing `theme`, `tokens`, `services`. The home-manager module writes that
file from `programs.arcshell.settings` and restarts the service on change.

## Design tokens (config/tokens/)

- `system/` — global vocabulary: `Animations` (curves + durations), `Colors`,
  `Shapes`, `Measurements`, `Fonts`, `Typography`.
- `component/` — per-component tokens (`Launcher`, `Notification`, `Slider`,
  …). Components bind them once: `property ComponentTokens.Launcher theme:
  Config.tokens.component.launcher` and read `theme.*` everywhere.
- `types/` — small value bundles (`AnimationValues` = curveIn/curveOut/
  duration, `PaddingValues`, `SurfaceColorValues`, …) with defaults pointing
  at system tokens.
- `feature/` — feature-level tokens (clock, workspaces, power…).

All token files are `JsonObject`s, so everything is user-overridable from
`shell.json` by the same path (`tokens.component.launcher.lineSweepFraction`).

Animation conventions:

- Curves are flat `list<real>` Bezier control points (`easing.type:
  BezierSpline` via the `AnimatedNumber`/`AnimatedColor` components —
  always use these, never raw `NumberAnimation`).
- `emphasizedIn` is the exact time-reverse of `emphasizedOut` (every point
  `p → 1 − p`, segment order flipped): In = slow build/fast finish for
  entrances, Out = fast start/decelerate for exits. Keep the pair in sync if
  either changes.
- Durations: `small 120 / medium 200 / large 400 / extraLarge 600 /
  twoExtraLarge 800` × `scale`. `AnimationValues` defaults to `medium`.
- Tune animations in the component token file, not in the QML — the wrapper
  reads `theme.animation.*`.

## QML conventions

- `pragma ComponentBehavior: Bound` on files with inline components or
  delegates; root element always has `id: root`; delegates/inline components
  reference `root.*` explicitly.
- `required property` for injected context (`screen`, `bar`, `wrapper`).
- Derived values are `readonly property` bindings on the root, not functions.
- Comments explain *why* (compositor quirks, ordering constraints, design
  intent), not what. Preserve them when refactoring; several encode
  hard-won Hyprland behavior (see Hud.qml's grab/focus comments).
- Content-driven resizes (e.g. launcher candidate list) animate via `Behavior
  on implicitHeight` in the Content, while open/close animates the Wrapper —
  the two compose because the wrapper multiplies content size by progress.
- Items don't clip by default: children of a zero-height Item still render.
  The launcher's phase-1 sweep line depends on this; its wrapper floors
  `implicitHeight` at the border thickness so it never becomes a zero-size
  item.

## Dev workflow

Run a dev instance against the working tree (the systemd service runs the
nix-store build, not your edits):

```sh
systemctl --user stop arcshell && pkill -f 'bin/quickshell'
nix develop .#arcshell -c sh -c \
  'export PATH=$PATH:/etc/profiles/per-user/$USER/bin; exec qs -p modules/home/_arcshell' \
  > /tmp/arcshell.log 2>&1 &
```

- Sanity: `hyprctl layers -j | grep -c arc-shell-hud` → one per screen.
- Logs: watch `/tmp/arcshell.log` for `Binding loop`, `Unable to assign`
  (dangling token reference resolves to `undefined`), `TypeError`,
  `ReferenceError`.
- Global shortcuts: this Hyprland's `hyprctl` evaluates Lua —
  `hyprctl dispatch 'hl.dsp.global("nix-config-shell:launcherToggle")'`.
  List registered ones with `hyprctl globalshortcuts`.
- Visual verification: `grim -g 'X,Y WxH' out.png` with *logical*
  coordinates; PNG pixels = logical × display scale. Screenshot mid-animation
  by chaining toggle + sleeps in one script.
- Keystrokes reach the focused launcher input via `wtype` (virtual keyboard
  events pass the focus grab).
- Restore when done: `pkill -f 'bin/quickshell' && systemctl --user start
  arcshell`.

QML has no compile step here — the dev instance's startup log is the type
checker. A clean startup plus an exercised open/close of the affected panel is
the minimum bar before shipping.

## Gotchas

- The `qs.*` module cache follows directories: renaming/moving a QML file
  changes its import path for every consumer; grep `import qs.` before moving.
- Token renames fail silently at the QML level (undefined binding + runtime
  warning, no hard error) — after renaming a token, grep for the old name AND
  scan the dev-instance log for `Unable to assign [undefined]`.
- `hyprctl dispatch global …` (upstream syntax) does not work on this config;
  use the Lua form above.
- The HUD input mask is computed from `panels.children` — a new panel gets
  mouse input for free, but anything outside `Panels` needs a mask `Region`.
- Hyprland allows one seat grab: never add a second `HyprlandFocusGrab`
  driven by the same condition as the existing one in `Hud.qml`.
