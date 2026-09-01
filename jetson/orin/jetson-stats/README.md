# jetson-stats

This RPM packages upstream `jetson-stats` and its `jtop` service without the
side effects of upstream's root-level pip installer.

Lumina carries two integration changes:

- recognize L4T 39.2.1 as JetPack 7.2.1;
- authorize members of Fedora's existing `wheel` administrator group instead
  of creating a group that GNOME Initial Setup users would not join.

The RPM owns the systemd unit and preset directly. It does not create files in
`/usr/local`, mutate users during the build, or run pip on the installed system.
