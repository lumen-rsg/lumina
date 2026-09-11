# Cassiopeia desktop acceptance

## Release scope

- Lumina 26.9 "Cassiopeia" identity and artwork; Fedora releasever remains 44.
- Native ARM64 and x86-64 desktop RPM targets and UEFI composition.
- Chroma compositor with Lumina's end-4-derived Quickshell configuration.
- No anime imagery, image-board service, character prompts, or end-4 branding
  in the installed shell; upstream licensing and attribution are preserved.
- Cloud-first assistant with explicit provider/model selection and private
  credential storage, cancellation, errors, and conversation reset.
- Required third-party package sources moved into LuminaCI recipes, with
  provenance and source pins; no client-side COPR dependency.

## Gates

- [x] Source manifest, dependency graph, dual-target registration and whitespace checks.
- [ ] Native ARM64 RPM builds and dependency closure.
- [ ] Native x86-64 RPM builds and dependency closure.
- [x] Headless Chroma + Lumina shell integration and screenshot review (1280x800, one output).
- [ ] Signed LuminaCI repository publication on both architectures.
- [ ] ARM64 UEFI image installs and boots to the desktop.
- [ ] x86-64 UEFI image installs and boots to the desktop.
- [ ] Physical-device graphics, input, audio, networking, locking, suspend,
  portals, and multi-monitor qualification.

An RPM build or headless render does not establish installable-media or
physical-device acceptance. Existing Jetson and Orange Pi hardware recipes
retain their board-specific boot paths.

## Local evidence, 2026-09-11

Fedora 44 aarch64 disposable builder, Qt 6.11.2. Chroma source build
passed five non-integration suites. Quickshell passed nine CTest suites
under Xvfb after a downstream test-only asynchronous reposition fix.
The AI helper passed 21 unittest cases (including inherited repetitions),
and the actual QML/helper/local HTTP round trip passed. This uses a fake
provider and is not a live paid-provider credential test.

The headless shell connected to Chroma, observed a real Wayland window,
and opened assistant, overview, launcher, settings, notifications and clock.
Screenshots and logs were written to
`/tmp/lumina-cassiopeia-upstream/qa2` on the development host. These temporary
files are evidence for this run, not release artifacts. Expected warnings
include absent UPower in the isolated session. No QML errors were observed.

The generated Cassiopeia background is 1672x941 pixels. The existing Lumina
vector marks remain scalable. No 4K native wallpaper claim is made.

Full upstream dotfiles parity remains open; see `PORT.md` and the explicit
unported dependency list in `../packaging/MIGRATION.md`. RPM publication and
installable media are not established by the checks above.
