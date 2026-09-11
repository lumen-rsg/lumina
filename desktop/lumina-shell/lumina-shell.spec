Name:           lumina-shell
Version:        26.9
Release:        1.lu26
Summary:        Cassiopeia desktop shell derived from end-4 dotfiles
License:        GPL-3.0-only
URL:            https://github.com/lumen-rsg/lumina
Source0:        lumina-shell-26.9.tar.gz
Source1:        lumina-shell
Source2:        lumina-assistant
BuildArch:      noarch
Requires:       quickshell >= 0.3.0
Requires:       qt6-qt5compat
Requires:       qt6-qtsvg
Requires:       qt6-qtimageformats
Requires:       qt6-qtwayland
Requires:       google-sans-flex-vf-fonts
Requires:       google-material-symbols-vf-rounded-fonts
Requires:       lumina-artwork >= 26.9
Requires:       python3
Requires:       pavucontrol
Requires:       nm-connection-editor
Requires:       blueman
Requires:       wdisplays
Provides:       desktop-notification-daemon

%description
Lumina's Material desktop shell based on end-4's portable Quickshell
components, with native Chroma spatial controls and a user-configured AI
assistant. No anime content or upstream Chroma shell is included.

%prep
%autosetup

%build

%install
mkdir -p %{buildroot}%{_datadir}/lumina-shell
cp -a shell/. %{buildroot}%{_datadir}/lumina-shell/
install -Dpm0755 %{SOURCE1} %{buildroot}%{_bindir}/lumina-shell
install -Dpm0755 %{SOURCE2} %{buildroot}%{_libexecdir}/lumina-assistant

%files
%license LICENSE
%doc UPSTREAM.json
%{_datadir}/lumina-shell/
%{_bindir}/lumina-shell
%{_libexecdir}/lumina-assistant

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 26.9-1.lu26
- Initial Cassiopeia Material shell and provider-selected assistant
