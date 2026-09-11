# Cassiopeia desktop acceptance

## Release scope

Lumina 26.9 “Cassiopeia” targets generic ARM64 and x86-64 UEFI desktops on
Fedora 44. Chroma runs the end-4-derived Lumina shell; Chroma's bundled
Quickshell is excluded. The installed shell contains no anime assets,
image-board services, character prompts or end-4 branding. Upstream licensing
and attribution are retained. The assistant is cloud-first with explicit
provider/model selection and private credential storage.

The implemented shell is an initial component-based port. **Full upstream
module parity is not complete**; `PORT.md` and `../packaging/MIGRATION.md`
list the outstanding modules and optional dependencies.

## Gates as of 2026-09-11

- [x] Source bundles, provenance, spec paths and whitespace checks.
- [x] Actual LuminaCI project planner accepts both architecture manifests.
- [x] Native ARM64/noarch RPM builds and an empty-root Fedora dependency transaction.
- [x] Chroma + shell rendering, notifications, two outputs and 200% scaling.
- [x] Real QML control requests change Chroma zoom and close a test window.
- [x] Real QML/helper/HTTP assistant round trip with a simulated provider.
- [x] ARM64 development network ISO composition, media checksum and UEFI boot to Anaconda.
- [ ] Native x86-64 RPM builds and empty-root dependency closure.
- [ ] Signed LuminaCI publication for both architectures.
- [ ] ARM64 installer completes installation and boots the installed desktop.
- [ ] x86-64 installer completes installation and boots the installed desktop.
- [ ] Physical graphics, input, audio, networking, locking, suspend, portals,
  multi-monitor behavior and Secure Boot qualification.

## Source and package evidence

Native local builder: Fedora 44 aarch64, Qt 6.11.2. All ten binary RPMs and
matching source RPMs are in `desktop/dist/{RPMS,SRPMS}`. Their SHA-256 hashes
are recorded in `LOCAL-RPMS-2026-09-11.sha256` and `desktop/dist/SHA256SUMS`.
These RPMs are unsigned development artifacts.

- Chroma pin: `c310258dbf1c71b3cf4a4474a9680f07bfdd2e4c`; five non-integration
  suites passed in its native build.
- Quickshell pin: `2d3b3e9c70ef380dff751b61d334dc88df016c29`; all nine CTest
  suites passed under Xvfb with the documented test-only asynchronous popup fix.
- `wl-clip-persist` built from pinned source and its vendored lockfile offline.
- End-4 source pin and imported file list: `lumina-shell/UPSTREAM.json`.
- The empty-root transaction installed 720 packages from Fedora 44 release,
  Fedora updates and the ten local RPMs, with no COPR enabled. Final changed
  RPMs were reinstalled and verified with `rpm -V`. The installed Quickshell
  executable ran successfully. A udev hardware-database scriptlet reported
  “Function not implemented” inside the container; this is not boot validation.
- The actual `ProjectDispatchPlanResolver` from the local LuminaCI checkout
  accepted the main 34-package graph and each 10-package desktop graph.
  Each desktop graph resolved four stages. One target per binding and separate
  per-architecture promotion groups are required; see `CI.md`.

## Shell and assistant evidence

`smoke-shell.sh` starts an isolated D-Bus session, headless Chroma, PipeWire,
a real Wayland terminal and Lumina Shell. It checks the compositor connection,
window discovery, notifications and six panels, then executes the QML zoom
and window-close fixture. This caught and fixed the missing `action ` prefix
in the initial Chroma adapter.

Rendering passed at 1280x800, two 1280x800 outputs, and 1920x1200 at scale 2.
Screenshots were visually reviewed. The test session lacks UPower, so battery
hardware behavior is unverified. No QML errors remained in passing runs.

The assistant helper passed 11 distinct unittest cases. The QML integration
fixture configured a local simulated OpenAI-compatible provider, sent a chat
and verified the displayed response and mode-0600 settings. This caught and
fixed the initial configuration race. No paid provider credentials were used;
live cloud account compatibility and cancellation during a real cloud request
remain unqualified. Provider keys are neither printed nor passed in argv.

Evidence logs and screenshots are retained locally under
`desktop/evidence/local-20260911/`. This directory and `desktop/dist/` are
ignored by Git; the acceptance record and RPM hashes are committed.

## Media and remaining release work

`installer/build-iso.py` produces a network installer from a signed and
SHA-256-verified Fedora Everything 44 base ISO. Both architecture profiles
pass `ksvalidator -v F44`. The build preserves EFI loaders, reconstructs the
FAT image using mtools, and supplies a Lumina Anaconda product image.

The ARM64 development image is
`desktop/dist/Lumina-26.9-Cassiopeia-aarch64-development.iso`, with adjacent
ISO and package SHA-256 manifests. It requires network access for Fedora
packages. Earlier development media booted to the graphical Anaconda summary
under QEMU/KVM with EDK2 UEFI, loaded the package profile and displayed the
Lumina identity. Disk selection is interactive. The final account-profile
verification is recorded in the accompanying boot evidence below.

Anaconda treats any kickstarted root password command, including a locked
root account, as an administrator configuration. The final profile therefore
leaves account setup to the UI, hides the root-password spoke and locks root
in `%post`, so an administrator user must be created.

The generated Cassiopeia wallpaper is 1672x941 pixels; vector marks remain
scalable. A native 4K wallpaper is not claimed.

The signed-in CI console rejected build
`cf9caeb7-4e44-4d53-8794-60b420d3918c` before execution because a verified
repository-project snapshot was missing. Project API/administration access
is still needed; the console's standalone trigger cannot supply that snapshot.
No remote desktop build, signing or publication succeeded in this run.

## Final ARM64 boot evidence

The exact final ISO booted to the Lumina-branded graphical Anaconda summary
under QEMU 10.2.2/KVM with EDK2 UEFI, four vCPUs, 4 GiB RAM and a new empty
24 GiB virtual disk. Fedora network source and the custom package selection
loaded successfully. Both disk selection and User Creation were marked
required; the root-password spoke was hidden and Begin Installation remained
disabled. No installation or disk partitioning was performed.

Screenshot and serial log:
`desktop/evidence/uefi-aarch64-final/{installer.png,serial.log}`.

ISO size: `1397030912` bytes. SHA-256:

`6397b0790ac0c6265b11dc61060751be1fd4809a2cc112fb4619b56978e82adf`
