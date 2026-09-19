# Lumina 26.9 Cassiopeia desktop

The desktop edition targets Fedora 44 on native `aarch64` and `x86_64`
UEFI systems. Chroma supplies the compositor; Lumina Shell is a downstream
fork of end-4's portable Quickshell components, with Lumina panels and a
native Chroma spatial backend. Chroma's bundled shell is not installed.

Shell release 4 merges Chroma's spatial overview, operation feedback, shortcut
guide and Forest/Sandy palettes into Cassiopeia. See the
[spatial release notes](docs/SPATIAL-SHELL-2026-09-19.md) for update instructions
and signed publication evidence for both architectures.

The AI assistant is cloud-first with a user-selected provider. No account,
credential, model download, or outbound AI request is enabled by default.

Package recipes have separate ARM64 and x64 project manifests under `.lumina/`.
See `docs/CI.md` for LuminaCI's single-target binding requirement.
Desktop installations use Fedora and signed Lumina repositories;
they do not enable COPRs or run the upstream dotfiles installer.

See `docs/ACCEPTANCE.md` for the distinction between implemented source,
locally built artifacts, CI publication, and boot qualification.

`installer/` composes a generic UEFI network installer from verified Fedora
media and the Lumina RPM set. It does not replace the board installers.
