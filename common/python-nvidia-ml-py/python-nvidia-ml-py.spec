Name:           python-nvidia-ml-py
Version:        13.595.45
Release:        1.lu26
Summary:        Python bindings for the NVIDIA Management Library
License:        BSD-3-Clause
URL:            https://pypi.org/project/nvidia-ml-py/
Source0:        https://files.pythonhosted.org/packages/ce/49/c29f6e30d8662d2e94fef17739ea7309cc76aba269922ae999e4cc07f268/nvidia_ml_py-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  python3-wheel
BuildRequires:  pyproject-rpm-macros

%description
The NVIDIA-supported Python interface to NVML, used by jetson-stats for GPU
identity, process, and utilization information.

%package -n python3-nvidia-ml-py
Summary:        %{summary}

%description -n python3-nvidia-ml-py
%{description}

%prep
%autosetup -n nvidia_ml_py-%{version}

%generate_buildrequires
%pyproject_buildrequires

%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files pynvml example

%check
%pyproject_check_import

%files -n python3-nvidia-ml-py -f %{pyproject_files}
%license README.txt

%changelog
* Wed Sep 02 2026 Lumina Linux <packages@linux.1t.ru> - 13.595.45-1.lu26
- Package the NVML Python bindings required by jetson-stats
