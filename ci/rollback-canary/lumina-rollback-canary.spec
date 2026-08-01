Name:           lumina-rollback-canary
Version:        2
Release:        1.lu26
Summary:        LuminaCI repository rollback exercise canary
License:        MIT
BuildArch:      noarch

%description
An inert marker package used to exercise native promotion and administrator
rollback without changing a production package set.

%prep

%build

%install
install -Dpm0644 /dev/null %{buildroot}%{_datadir}/lumina-ci/rollback-canary
printf 'version=%s\n' '%{version}' > %{buildroot}%{_datadir}/lumina-ci/rollback-canary

%files
%{_datadir}/lumina-ci/rollback-canary

%changelog
* Sat Aug 01 2026 Lumina Linux <packages@linux.1t.ru> - 2-1.lu26
- Exercise a superseding promotion before administrator rollback

* Sat Aug 01 2026 Lumina Linux <packages@linux.1t.ru> - 1-1.lu26
- Establish the isolated repository rollback baseline
