Name:           aurora
Version:        1.0.0
Release:        1.lu26.03
Summary:        Modern orchestrator and package manager for Lumina OS
License:        GPLv3
URL:            https://github.com/lumen-rsg/aurora
Source0:        %{name}-%{version}.tar.gz

# NativeAOT Build Requirements
BuildRequires:  dotnet-sdk-10.0
BuildRequires:  clang
BuildRequires:  zlib-devel
BuildRequires:  openssl-devel
BuildRequires:  krb5-devel
BuildRequires:  binutils

# Runtime Requirements
# Aurora is a frontend; it requires the actual RPM binary to perform transactions.
Requires:       rpm
Requires:       coreutils
Requires:       tar
Requires:       zstd
Requires:       gnupg2
Requires:       ca-certificates
Requires:       bzip2

%description
Aurora is the primary package management frontend for Lumina OS. 
It features a parallelized download engine, a high-performance 
SQLite-based repository solver, and an integrated system bootstrapper.
Compiled to native machine code via .NET AOT.

%prep
%setup -q

%build
# Set DOTNET variables for clean AOT build
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

# Determine Runtime Identifier based on architecture
%ifarch x86_64
  %define rid linux-x64
%endif
%ifarch aarch64
  %define rid linux-arm64
%endif

# Build the CLI (au)
dotnet publish Aurora.CLI/Aurora.CLI.csproj \
    -c Release \
    -r %{rid} \
    --self-contained \
    -p:PublishAot=true \
    -p:ConsoleLoggerParameters=Summary \
    -o build_output/cli

# Build the Installer
dotnet publish Aurora.Installer/Aurora.Installer.csproj \
    -c Release \
    -r %{rid} \
    --self-contained \
    -p:PublishAot=true \
    -o build_output/installer

%install
# Create directory structure
install -d -m 755 %{buildroot}%{_bindir}
install -d -m 755 %{buildroot}%{_libdir}
install -d -m 755 %{buildroot}%{_localstatedir}/lib/aurora
install -d -m 755 %{buildroot}%{_localstatedir}/cache/aurora

# Install Binaries
install -p -m 755 build_output/cli/au %{buildroot}%{_bindir}/au
install -p -m 755 build_output/installer/Aurora.Installer %{buildroot}%{_bindir}/lumina-installer

# Install Native SQLite engine (required for AOT Microsoft.Data.Sqlite)
# We move this to the standard system library path
if [ -f build_output/cli/libe_sqlite3.so ]; then
    install -p -m 755 build_output/cli/libe_sqlite3.so %{buildroot}%{_libdir}/libe_sqlite3.so
fi


# Executables
%{_bindir}/au
%{_bindir}/lumina-installer

# Libraries
%{_libdir}/libe_sqlite3.so

# State Directories
%dir %{_localstatedir}/lib/aurora
%dir %{_localstatedir}/cache/aurora

%changelog
* Mon Mar 21 2026 Lumen Research Group <github@lumen-rsg> - 1.0.0-1
- Created the RPM spec file.