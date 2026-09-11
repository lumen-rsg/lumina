%global commit e26fde01c13922e3a65049dafb7d5adfbc52626e
Name:           wl-clip-persist
Version:        0.5.0
Release:        1.lu26
Summary:        Persist Wayland clipboard contents after the owner exits
License:        MIT AND Unicode-3.0
URL:            https://github.com/Linus789/wl-clip-persist
Source0:        https://github.com/Linus789/wl-clip-persist/archive/%{commit}/wl-clip-persist-%{commit}.tar.gz
Source1:        wl-clip-persist-vendor-%{version}.tar.gz
ExclusiveArch:  aarch64 x86_64
BuildRequires:  rust >= 1.85
BuildRequires:  cargo
BuildRequires:  gcc

%description
Clipboard persistence for compositors supporting the Wayland data-control
protocols. Built offline from pinned source and Cargo.lock dependencies.

%prep
echo '4f57033dae159b887168210bcc69de84ba5f43e7e39444e483297e6ccb4b747c  %{SOURCE0}' | sha256sum -c -
echo '24587504888f91b485e68bfee476be3d6e73fb704a45933d98b30df8204378a8  %{SOURCE1}' | sha256sum -c -
%autosetup -n wl-clip-persist-%{commit}
tar -xf %{SOURCE1}
mkdir -p .cargo
cat > .cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = "vendored-sources"
[source.vendored-sources]
directory = "vendor"
EOF

%build
export CARGO_NET_OFFLINE=true
cargo build --release --frozen

%check
cargo test --release --frozen

%install
install -Dpm0755 target/release/wl-clip-persist %{buildroot}%{_bindir}/wl-clip-persist
# Preserve bundled dependency license notices alongside the upstream license.
mkdir -p %{buildroot}%{_licensedir}/%{name}/vendor
find vendor -type f \( -iname '*license*' -o -iname '*copying*' -o -iname '*notice*' \) -exec cp --parents '{}' %{buildroot}%{_licensedir}/%{name}/ \;

%files
%license LICENSE
%doc README.md
%{_licensedir}/%{name}/vendor/
%{_bindir}/wl-clip-persist

%changelog
* Fri Sep 11 2026 Lumina Linux <packages@linux.1t.ru> - 0.5.0-1.lu26
- Build Chroma clipboard persistence natively in LuminaCI
