# Dotfiles dependency migration

Source: `end-4/dots-hyprland/sdata/dist-fedora/feddeps.toml` at the revision
recorded in `lumina-shell/UPSTREAM.json`. Its installer enables five COPRs and
also downloads prebuilt packages from `end-4/ii-package-builds`.

Cassiopeia never runs that installer. Fedora supplies packages that already
exist there; required missing/versioned packages are owned by LuminaCI.
All new recipes target **fedora-44-aarch64 and fedora-44-x86_64** in
`.lumina/packages.yaml` and form the `cassiopeia-desktop-26.9` promotion group.

| Upstream channel | Required disposition for the current shell |
| --- | --- |
| ririko66z/dots-hyprland | Google Sans Flex, Material Symbols Rounded, and Bibata recipes live under `desktop/` with immutable upstream URLs and SHA-256 checks |
| sdegler/hyprland | Hyprland stack replaced by Chroma, swaylock/swayidle, wlr/GTK portals, grim/slurp/wf-recorder; Fedora 44 supplies wlroots 0.20 |
| deltacopy/darkly | Not required by the initial port; Qt Quick uses Basic controls with the retained Material widgets |
| alternateved/eza | eza exists in Fedora 44; no COPR migration required |
| atim/starship | Not used by the initial shell; retain as follow-up if upstream terminal configuration is imported |
| end-4/ii-package-builds | New native Quickshell recipe; current Fedora Quickshell repositories observed during discovery were older than the required 0.3 APIs |

The required font recipes were reconstructed from pinned upstream sources.
The COPR API enumerated the original package names, but its dist-git HTTP
frontend returned an Anubis challenge and its temporary uploads were not
usable. These are Lumina-maintained replacements, not an asserted verbatim
import of inaccessible COPR specs. `sources.json` retains font provenance.
Bibata RPMs contain upstream architecture-independent Xcursor art; the source
RPM includes its editable SVG source archive.

Quickshell uses private Qt ABI. Its recipe requires the exact Qt base EVR used
by the native builder. Qt updates therefore require rebuilding Quickshell
before desktop promotion. The optional cpptrace crash handler is disabled in
this first package, avoiding the old breakpad/cpptrace COPR build chain;
regular system coredumps remain available. Hyprland-specific integrations
are disabled at build time.

Matugen already exists in Fedora, but wallpaper-driven Material generation
is not yet ported. MicroTeX, additional upstream font families, darkly,
starship, music recognition and the remaining upstream optional utilities
are not migrated by this change because their consuming modules are not
ported. Their absence must not be presented as complete dependency migration
or full dotfiles parity. No third-party binary RPM feed is enabled on clients.

Native package build, source verification and dependency-closure results
belong in `docs/ACCEPTANCE.md`. Manifest entries alone do not prove remote CI
execution, signing, mirroring or installation.
