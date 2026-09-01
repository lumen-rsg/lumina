Name:           python-smbus2
Version:        0.6.1
Release:        1.lu26
Summary:        Python SMBus access through the Linux I2C device interface
License:        MIT
URL:            https://github.com/kplindegaard/smbus2
Source0:        https://files.pythonhosted.org/packages/87/37/b3f7b501502c4915ba3819d1dc277bf3f5fae4a9d067caa4f502aaddd889/smbus2-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  python3-wheel
BuildRequires:  pyproject-rpm-macros

%description
A drop-in Python replacement for smbus-cffi and python-smbus that provides
SMBus and I2C access through Linux's i2c-dev interface.

%package -n python3-smbus2
Summary:        %{summary}

%description -n python3-smbus2
%{description}

%prep
%autosetup -n smbus2-%{version}

%generate_buildrequires
%pyproject_buildrequires

%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files smbus2

%check
%pyproject_check_import

%files -n python3-smbus2 -f %{pyproject_files}
%license LICENSE
%doc README.md

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 0.6.1-1.lu26
- Package smbus2 for Jetson hardware monitoring
