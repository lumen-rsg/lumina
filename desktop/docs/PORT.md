# end-4 port boundary

The source pin and exact imported files are in `lumina-shell/UPSTREAM.json`.
The first port retains end-4's Material appearance, typography, ripple buttons,
icons, text rendering, and portable drawing components. Lumina owns the panel
composition and replaces all compositor-specific behavior with Chroma's v2
control socket and standard Wayland layer shell. No files from Chroma's default
Quickshell are imported into Lumina Shell.

| Upstream function | Cassiopeia implementation |
| --- | --- |
| Hyprland workspaces and overview | Chroma windows, canvas zoom, teleport points, focus/bring/close, tiling/restore |
| Hyprland global shortcuts | Chroma key bindings call stable shell IPC targets |
| Hyprland focus grab | Exclusive layer-shell keyboard focus; Escape and Close dismiss the drawer |
| Wallpaper | Lumina Cassiopeia artwork and editable wallpaper path |
| AI tab | Provider picker, model and endpoint, private credentials, chat, cancellation, new conversation |
| Control center | Upstream ii grouping, Material toggle pills and sliders, live network/power status, audio/mic, DND, theme, notifications and calendar |
| Settings | Separate window with upstream navigation rail; Quick, General, Bar, Background, Interface, Services, Advanced and About pages |
| Sidebar widgets | Collapsible Calendar / To Do / Timer rail, saved tasks, focus/break cycles, stopwatch and laps |
| Media | MPRIS player selection, art, metadata, play/pause, previous/next and seeking |
| Audio, tray, battery, notifications | Quickshell service APIs; external device managers for detailed configuration |
| Screenshot, lock, idle, clipboard, portals | Chroma session helpers and wlroots/GTK portals |
| Anime/image-board content and character prompts | Excluded from the shipped source selection entirely |
| Upstream identity | Lumina shell identity; upstream attribution retained in package documentation |

This is an initial component-based port, **not full feature parity with the
upstream ii or waffle panel families**. The upstream dock, calendar event integration,
notification persistence, detached/pinned AI sidebar, live window thumbnails,
wallpaper browser and dynamic Material generation, OCR/translation/Lens,
audio visualization/lyrics, keyboard, and the remaining accessibility settings
remain follow-up scope. Embedded Wi-Fi/Bluetooth pairing and per-application
audio panes still open Fedora device managers; night light and tile rearrangement
are not yet ported. Do not advertise these as implemented.

The assistant currently renders selectable plain text. It does not execute
commands, read windows, attach screenshots, or persist conversation history.
Cloud use starts only after the user selects a provider/model, supplies a key,
and sends a message. Keys live in a mode-0600 file at
`$XDG_CONFIG_HOME/lumina/assistant.json`, never in argv or shell.json. Changing
provider or endpoint cannot silently reuse a previous credential. Redirects
are refused so credentials cannot follow a response to another origin.

Protocol references: [Chroma source](https://github.com/lumen-rsg/chroma),
[Gemini generateContent](https://ai.google.dev/api/generate-content),
[Ollama chat](https://docs.ollama.com/api/chat), and
[Anthropic Messages](https://docs.anthropic.com/en/api/messages).

Quickshell packaging carries one test-only patch: `moveWithParent` now waits
for the scheduled popup polish before asserting its coordinates. The
production code already schedules this asynchronously. The unpatched suite
failed the same assertion under offscreen and Xvfb; all nine tests pass under
Xvfb with the wait. No production toolkit behavior was changed by that patch.

## Control center and settings continuation (2026-09-12)

The earlier generic settings drawer is replaced by the ii-shaped control
center. Eighteen additional upstream Material widgets are retained directly;
UPSTREAM.json records the source and adapted layouts. A separate settings
window exposes working, persistent controls rather than empty upstream tabs.
Theme, panel transparency, motion, font, bar modules, clock format, wallpaper,
notification duration, DND and control-center preferences apply immediately.
A 150 ms write debounce prevents rapid edits from racing FileView's reload.
PreferenceSwitch keeps the upstream switch's editable state synchronized with
external model changes.

Control actions use Pipewire/Bluetooth APIs or the allowlisted lumina-controls
helper. Unavailable hardware is disabled or hidden; errors are shown instead
of optimistic success. Brightness requests retain the latest value during an
in-flight write. Network, Bluetooth, sound and display details launch the
packaged Fedora managers. Calendar month navigation and Today work; its compact
control-center button opens the larger calendar on short displays.

This is lumina-shell 26.9-2.lu26 development work. The b1feea2 signed installer
images and their exact-image acceptance record still describe release 1 of
the shell. This continuation has not yet been published by LuminaCI or composed
into new installer images. See PARITY-2026-09-12.md for validation.

## Sidebar widgets continuation (2026-09-18)

Shell release 3 restores the upstream lower-group navigation: Calendar, To Do
and Timer, with Pomodoro/Stopwatch inside Timer. It starts collapsed so the
three entry points remain visible on short displays; expanding scrolls the
control center to the group. The clock opens the expanded calendar group.
Tasks support completion, reopening, deletion and undo. Tasks, focus deadlines,
stopwatch elapsed time and laps persist in `lumina/productivity.json` alongside
the shell preferences. Invalid saved data is kept intact with editing disabled.
Focus/break transitions pause for the user; every fourth focus session offers a
long break. Completion emits a local desktop notification, respecting DND.

The media card appears for MPRIS players and follows their capabilities. It
supports player selection, artwork, metadata, transport and seeking. Artwork
uses Qt image loading, without spawning shell commands. It does not add the
upstream Cava visualizer or lyrics. Settings expose media/widget visibility and
focus/break durations. The imported scrollbar has a narrow sizing fix to avoid
a Qt binding loop. See [PARITY-2026-09-18.md](PARITY-2026-09-18.md) for evidence.

Release 3 is an unsigned development RPM. This continuation does not update
LuminaCI publication or the previously qualified installer images.
