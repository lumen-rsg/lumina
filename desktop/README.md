# Lumina 26.9 Cassiopeia desktop

The desktop edition targets Fedora 44 on native `aarch64` and `x86_64`
UEFI systems. Chroma supplies the compositor; Lumina Shell is a downstream
fork of end-4's portable Quickshell components, with Lumina panels and a
native Chroma spatial backend. Chroma's bundled shell is not installed.

The AI assistant is cloud-first with a user-selected provider. No account,
credential, model download, or outbound AI request is enabled by default.

Package recipes are registered in the repository's `.lumina/packages.yaml`
for LuminaCI. Desktop installations use Fedora and signed Lumina repositories;
they do not enable COPRs or run the upstream dotfiles installer.

See `docs/ACCEPTANCE.md` for the distinction between implemented source,
locally built artifacts, CI publication, and boot qualification.
