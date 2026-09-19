# Cassiopeia and Chroma shell integration

Cassiopeia release 4 integrates the spatial components from Chroma's reference
shell while retaining the Material shell, control center, settings, assistant,
productivity widgets, media controls and Lumina identity.

- The canvas overview is a centered spatial map with window placement,
  viewport bounds, search by title/application, focus/bring/close actions,
  saved points, rename/remove (right-click or F2), zoom, arrangement and recovery.
  Empty canvases and the compositor's bounded/truncated window list are handled.
- The controls guide uses `chroma-settingsctl bindings` to show effective
  shortcuts, including configured spawn arguments. `hints toggle` opens the
  guide; the bar also has a keyboard button.
- Operation popups appear on every output without taking keyboard or pointer
  input. New feedback serials trigger them; repeated state updates do not extend
  the timeout. Rejected actions and disconnected control produce warnings.
- Cassiopeia, Muted Forest and Sandy palettes are selectable under Settings →
  Quick / Background. Forest and Sandy retain Chroma's original semantic colors,
  mapped throughout Cassiopeia's Material controls. Light/Dark select the
  corresponding Cassiopeia variant. Settings persist in Lumina's existing config.

Chroma source `319c020a2eab9c8874547c2cd4ac88b732738492`, pushed on
`codex/cassiopeia-shell-integration`, delegates startup and IPC to Cassiopeia when
installed. Standalone builds retain an explicit reference-shell fallback.
It adds bounded `mark_teleport` IPC, using the same nine-slot canvas and persistent
store as the keyboard action. The Lumina RPM continues to exclude the standalone
shell, retains the shipped clipboard patch and requires shell release 4.
The shell requires the new compositor so Save Point cannot be installed alone
against an older control protocol implementation. Existing unrelated edits in
`~/chroma` were neither committed nor included in the source archive.

## Verification

- Isolated ARM64 Chroma build from the committed source plus shipped clipboard
  patch; all five non-integration Meson suites pass, including protocol and theme
  contrast tests. Dispatcher tests verify startup, IPC, fallback and failures.
- Native Fedora 44 / Quickshell 2d3b3e9 headless checks pass at 1280×800 and on
  two 1920×1200 outputs at 200% scaling. No x64 emulator tests were resumed.
- The QML fixture drives viewport movement, point save/rename/jump/remove,
  window recovery, window search, effective shortcut decoding, map coordinate
  inversion, rejected-action warnings and serial-based feedback expiry.
- Both migrated palettes render correctly. Sandy persists across fresh shell
  processes. Screenshots include overview, guide, warning and settings surfaces.
- Source accounting and reproducible bundle checks pass; unsigned noarch RPM
  builds locally. New release delivery uses selective architecture manifests
  to reuse unchanged dependencies and publish the noarch shell once.

Raw development evidence is in `desktop/evidence/spatial-20260919/`. This is
native headless verification, not physical acceptance of release 4. The user's
v6 installation success covers the earlier shell 3 ISO; no new ISO is composed
by this shell update. CI signing/publication results are recorded separately.
