# Cassiopeia desktop acceptance

## Release scope

Lumina 26.9 “Cassiopeia” targets generic ARM64 and x86-64 UEFI desktops on
Fedora 44. Chroma runs the end-4-derived Lumina shell; Chroma's bundled
Quickshell is excluded. The installed shell contains no anime assets,
image-board services, character prompts or end-4 branding. Upstream licensing
and attribution are retained. The assistant is cloud-first with explicit
provider/model selection and private credential storage.

The implemented shell is an initial component-based port. **Full upstream
module parity is not complete**; `PORT.md` and `../packaging/MIGRATION.md`
list the outstanding modules and optional dependencies.

## Later shell development

The control-center/settings continuation is documented in
[PARITY-2026-09-12.md](PARITY-2026-09-12.md). It is a separately tested
development shell, not part of the signed `b1feea2` images below.
The [sidebar widgets/media continuation](PARITY-2026-09-18.md) advances the
development shell to release 3 with native ARM64 runtime evidence; it does
not requalify the earlier x86-64 preview or either installer image.

Release 3 was subsequently signed and published, and is included in the
[September 18 x64 NVIDIA installer candidate](INSTALLER-X64-NVIDIA-2026-09-18.md).
That exact image has package, native shell, NVIDIA module/initramfs and UEFI
boot evidence. A complete fresh installation and physical RTX 4090/Wi-Fi
acceptance are still open; the older signed images below remain unchanged.

## Gates as of 2026-09-12

- [x] Source bundles, provenance, spec paths and whitespace checks.
- [x] Actual LuminaCI project planner accepts both architecture manifests.
- [x] Native ARM64/noarch RPM builds and an empty-root Fedora dependency transaction.
- [x] Chroma + shell rendering, notifications, two outputs and 200% scaling.
- [x] Real QML control requests change Chroma zoom and close a test window.
- [x] Real QML/helper/HTTP assistant round trip with a simulated provider.
- [x] ARM64 development network ISO composition, media checksum and UEFI boot to Anaconda.
- [x] Native x86-64 RPM builds and complete empty-root desktop dependency closure.
- [x] Signed ARM64/noarch LuminaCI publication and public artifact verification.
- [x] Signed x86-64 LuminaCI publication and public artifact verification.
- [x] Signed ARM64 installer completes fresh installation, first login and VM session checks.
- [x] Signed x86-64 installer completes fresh installation, first login and VM session checks.
- [ ] Physical graphics, input, audio, networking, locking, suspend, portals,
  multi-monitor behavior and Secure Boot qualification.

## Published ARM64 candidate

Source `b1feea2561be5af626abd61970efc3b0b6299342` completed all ten ARM64/noarch
build, scan, sign and publication stages in delivery
`24c3e48b-6df6-4a2e-8d5b-1b0f6a53adc7`. Native promotion gate
`e33cd20f-81ba-8a14-a53d-af9186306e3f` passed at 20:52:20 UTC on September 11,
with result SHA-256
`dba3dc76870eb74bd43d8413171020a8ad2706c45f500d9f0e931b7ab7e463fc`.
The result records the ARM64 runner digest, Kubernetes Job UID and the complete
candidate inventory. Chroma's RPM check includes regular and primary clipboard
round trips.

All ten primary RPMs passed independent signature checks using the shipped
Lumina key (`EBE39C736CAC92CEC2139DC7620675824776D3D7`). Public `lumen/aarch64`
and `lumen/noarch` metadata and downloaded RPMs matched the signed CI artifact
hashes exactly. After confirming all publication stages, x64 delivery
`751fe2a3-cda9-412c-afb6-5ace1cae3775` was dispatched from the same source.
Its three native packages subsequently completed every build, scan, sign
and publication stage. The details are recorded below.

The signed-package ARM64 network installer is
`Lumina-26.9-Cassiopeia-aarch64-signed-b1feea2.iso`, SHA-256
`621547163747b58abf6868f8ad503e7794cf9628c4bef05e952be43fee864270`.
Composition verified the signed Fedora base checksum and all ten RPM signatures,
without the unsigned-development override. A fresh 32 GiB QEMU/KVM installation
installed 828 RPMs, rebooted automatically, and logged into Lumina without
package/configuration repairs. The installed compositor is release 2. Terminal
launch, canvas zoom/window close, regular and primary clipboard selections,
FileChooser portal selection, lock and password unlock passed. The assistant
opened its provider/model/key setup with Send disabled. SELinux remained
enforcing with no AVC records; no system services were failed. Root is locked
and the temporary evidence-collection SSH service is not enabled at boot.
DNF resolves `releasever=44` while the OS identifies itself as Lumina 26.9.
This is exact-image VM acceptance, not physical hardware qualification.
Evidence is retained under `desktop/evidence/installed-aarch64-signed/` and
`desktop/dist/ci-admin/`. The compact public record is
[`evidence/cassiopeia-aarch64-b1feea2.json`](evidence/cassiopeia-aarch64-b1feea2.json).

The preceding development image also passed a real FileChooser portal round
trip: a Gio request opened the GTK dialog, the QA user selected the Cassiopeia
wallpaper, and the portal returned response 0 with its file URI. This does not
qualify screencasting or physical-device behavior.

## Published x64 candidate

Delivery `751fe2a3-cda9-412c-afb6-5ace1cae3775` built and published the three
native x64 RPMs from `b1feea2`. Chroma passed five Meson tests and both
regular/primary clipboard round trips. Native gate
`32aef7b8-75c8-8d0b-bda4-97485516328c` passed at 21:27:38 UTC on September 11;
its result SHA-256 is
`1c3a30b03917d652a096f76a1e758d466292bde7d9c17baf095e6b338fc0a96f`.
Public `lumen/x86_64` and `lumen/noarch` metadata and all ten primary RPMs
matched the signed CI inputs. The seven noarch files are identical to the
ARM64 installer's shared packages.

A separate native Fedora 44 x64 container installed the complete
`lumina-desktop` dependency set into an empty root, with weak dependencies
excluded and package signature checking enabled. Its installed manifest has
727 RPM records. The installed `/bin/sh` and Quickshell executable ran;
verification of the desktop, shell, compositor, toolkit and clipboard RPMs was
clean. This transaction is separate from graphical boot acceptance.

Lorax requires matching host and ISO architectures. The x64 image was therefore
composed on the native x64 server, verifying the Fedora base's signed checksum
and all ten Lumina RPM signatures. The transferred image matched the server's
SHA-256:
`7d22a0b442e42fc686a01fd6a22b25983845ccd4635f8b080fa95e0555698e0b`.
Its filename is `Lumina-26.9-Cassiopeia-x86_64-signed-b1feea2.iso`.
UEFI boot reached branded Anaconda and the media check completed. The fresh
32 GiB installation installed 830 RPMs; its post-install scripts returned 0
at 22:19 UTC on September 11. After a host restart during the network outage,
the existing VM disk booted the installed system. First login selected Chroma
and Lumina Shell without package/configuration repairs or a session override.
This test used QEMU/TCG CPU emulation on the ARM host, with four virtual CPUs,
4 GiB RAM, OVMF UEFI and a single Virtio GPU; it is not native graphics or
physical hardware qualification.

Terminal launch, canvas zoom/window close, regular and primary clipboard
selections, FileChooser portal selection, and lock/password unlock passed.
The assistant opened explicit provider/model/key setup with Send disabled.
SELinux remained enforcing, with no AVC records in the installed session;
no system services were failed. Root is locked and guest SSH remains disabled
at boot. DNF resolves Fedora `releasever=44`, independently of the Lumina
26.9 identity. Desktop, shell, compositor, Quickshell and clipboard RPM
verification was clean. The clipboard fixture needed a bounded readiness
wait under TCG; its original 300 ms delay was too short. No installed package
was changed for that retry.

The installer environment's permissive SELinux messages and software-rendering
warnings are retained in the raw logs; the no-AVC result above applies to the
installed desktop boot. Evidence is under
`desktop/evidence/installed-x86_64-signed/`; the compact public record is
[`evidence/cassiopeia-x86_64-b1feea2.json`](evidence/cassiopeia-x86_64-b1feea2.json).
Both network installers require Fedora repository access during installation.
Their RPMs are signed; the complete ISO files are identified by SHA-256 and
are not separately GPG-signed.

## Fresh-install bootstrap correction

The development ISO with SHA-256 `6397b0790ac0c6265b11dc61060751be1fd4809a2cc112fb4619b56978e82adf`
was subsequently installed into a disposable 32 GiB ARM64 QEMU disk. Anaconda
downloaded 816 RPMs but failed the crypto-policies pre-install script: `/bin/sh`
could not execute because glibc had not yet installed its dynamic loader.
This supersedes the earlier boot-only observation below; that ISO does not
pass installation acceptance.

Replaying the exact cached RPM headers reproduced the wrong ordering.
`lumina-release` 2:26.9-2.lu26 marks its four post-transaction branding tools
as `Requires(meta)`, retaining runtime dependencies without bringing their
crypto stack into the release/setup/glibc bootstrap cycle. Ten shuffled
transaction-order checks put glibc before crypto-policies with no unresolved
dependencies. A fresh Fedora 44 container root then installed the complete
816-package selection, replacing only lumina-release, with RPM exit status 0.
All 816 package names were present, plus the imported Fedora public key;
`chroot ... /bin/sh` executed successfully. Container-only catalog, audit,
xattr and udev-hwdb warnings remain in the log. This is transaction evidence,
not installed-desktop boot acceptance.

Logs, the original RPM header archive and installer failure logs are retained
under `desktop/evidence/installed-aarch64-dev/`. Exact cached RPMs and the
rebuilt development ISO are retained under `desktop/dist/`.

## LuminaCI artifact correction

The corporate VPN restored SSH and both native workers. ARM64 retry
`52871873-0872-4e9d-afba-22aeca12c7cd` used source `60aeace2c49103abdb5d1a6c929f7e89fb7825a9`
but failed artifact ingestion: the service rejected the `^` in Quickshell's
valid RPM snapshot version. Other packages' publication stages were cancelled;
the x64 follow-up was not dispatched.

LuminaCI commit `09263b9` on `codex/rpm-snapshot-artifacts` shares the archive
and manifest filename validator and accepts RPM's `^` and `~` version operators.
All 241 build-service tests passed, including regression cases for snapshot
versions and unsafe paths. The service image `lumina-build-service:09263b9`
is deployed and healthy; public console and repository HTTPS returned 200.
The previous image and environment backup remain available for rollback.
Job identity, digest, signature, archive-path and publication checks remain
enforced.

Retry `c5ee534a-47c4-4d79-a177-67573794c184` built, scanned and signed all ten
ARM64/noarch packages from source `c4774c1`. All ten downloaded primary RPMs
passed independent signature and digest verification with the shipped Lumina
2026 key. Publication failed at native gate `60c92b37-85a6-818b-b123-0fc1c7f9bf6a`:
its separate Bash filename check also rejected `^`. LuminaCI commit `b665492`
corrects that check; all 249 BuildService tests pass, including execution of
the actual Bash condition with valid snapshot versions and unsafe names.
The deployed `lumina-build-service:b665492` is healthy, and console/repository
HTTPS returned 200. No publication gate was bypassed. The subsequent
`b1feea2` candidates passed their native transactions before publication,
as recorded above.

## Installed ARM64 session corrections

Development ISO SHA-256 `412db58c6cccd9ee88104ef0a7351d1b2e08bd46cae3db726073bd1ba81a83bd`
completed installation and rebooted into kernel `7.2.4-200.fc44.aarch64`,
but its original installed package selection did not reach the desktop.
Fedora's unrelated `chroma-1.21` puzzle game satisfied the old compositor
dependency, and the profile without weak dependencies omitted `dbus-daemon`
and `systemd-pam`. GDM could neither launch its session bus nor register a
user systemd manager.

The compositor RPM is now `chroma-compositor`, explicitly required by
`lumina-desktop` and conflicting with Fedora's game that owns the same binary
path. Desktop dependencies explicitly include both login components. The
updated local compositor build passed five tests. A DNF transaction in the
installed VM removed the game, installed the compositor and its dependencies,
and upgraded the desktop and Quickshell packages. GDM then worked.

GDM 50 does not use the old `DefaultSession` installer setting. AccountsService
templates now select Lumina for new standard and administrator accounts,
following the [documented template mechanism](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/setting-a-default-desktop-session-for-all-users).
A fresh QA administrator preselected Lumina and logged into Chroma with
Lumina Shell. The existing account retained its GNOME preference. The greeter
uses a 64-pixel white Lumina logo; the initial oversized SVG attempt was
replaced. The installed desktop displayed the Cassiopeia wallpaper and bar.
`chroma` and `quickshell` ran in a Wayland user session with SELinux enforcing.

This is a **repaired development VM**, not an exact signed-ISO acceptance pass.
Logs under `desktop/evidence/installed-aarch64-fixed/` retain the dependency
transactions and installed-session evidence. Portal app-ID registration and
VM camera/Bluetooth warnings remain unqualified. At this historical stage,
fresh signed media, x64 and physical-device acceptance were still open;
current results are listed above.

The next fresh development ISO, SHA-256
`97ddfe85df570369a04c10b5eb3caebfb90aaf7b6ac9174191f16465ca19a2d3`,
passed its boot-time media check, installed 828 RPMs into an empty 32 GiB ARM64
disk, rebooted into the branded greeter and logged into Lumina Shell without
post-install package or configuration repairs. Its package list contains
the corrected compositor identity and login dependencies. Evidence is under
`desktop/evidence/installed-aarch64-login/`. This image still predates the
clipboard correction below and is development media, not the signed release.

## Clipboard correction before publication

Installed-session QA confirmed terminal launch, canvas zoom from 100% to 110%,
window close, automatic idle lock and password unlock. No SELinux AVC records
were found in that VM. A regular clipboard probe failed, and the isolated
regular/primary selection fixture reproduced the failure on the pinned
compositor. It lacked handlers for wlroots seat selection requests.

The two-file clipboard fix already present in the separate local Chroma
checkout is carried as a Lumina RPM patch, based on upstream `c310258`, without
changing or committing that checkout's other work. `chroma-compositor`
release 2 passes the existing five tests and both clipboard round trips in
its RPM `%check`. The same test fails against the original installed RPM and
passes against the upgraded RPM inside the Fedora VM. The desktop release 3
dependency requires this correction. The patch and test are SRPM inputs;
neither imports Chroma's default Quickshell.

Delivery `17f14376-af3a-41bf-92b9-081f8e966eea` from `e8fbfc0` was deliberately
cancelled before publication after finding the clipboard defect. Six packages
had signed successfully; Quickshell was still compiling. Its status is failed
(`project-build-failed`) because its build was cancelled. The x64 follow-up
was not dispatched. The subsequent `b1feea2` matrix passed with the clipboard patch.

## Source and package evidence

Native local builder: Fedora 44 aarch64, Qt 6.11.2. All ten binary RPMs and
matching source RPMs are in `desktop/dist/{RPMS,SRPMS}`. Their SHA-256 hashes
are recorded in `LOCAL-RPMS-2026-09-11.sha256` and `desktop/dist/SHA256SUMS`.
These RPMs are unsigned development artifacts.

- Chroma pin: `c310258dbf1c71b3cf4a4474a9680f07bfdd2e4c`; five non-integration
  suites passed in its native build.
- Quickshell pin: `2d3b3e9c70ef380dff751b61d334dc88df016c29`; all nine CTest
  suites passed under Xvfb with the documented test-only asynchronous popup fix.
- `wl-clip-persist` built from pinned source and its vendored lockfile offline.
- End-4 source pin and imported file list: `lumina-shell/UPSTREAM.json`.
- The empty-root transaction installed 720 packages from Fedora 44 release,
  Fedora updates and the ten local RPMs, with no COPR enabled. Final changed
  RPMs were reinstalled and verified with `rpm -V`. The installed Quickshell
  executable ran successfully. A udev hardware-database scriptlet reported
  “Function not implemented” inside the container; this is not boot validation.
- The actual `ProjectDispatchPlanResolver` from the local LuminaCI checkout
  accepted the existing 26-package main graph, the 10-package ARM64 graph
  and the three-package x64 native graph.
  Desktop definitions are separate so the existing main project retains its
  live pipeline bindings, including the x64 distribution-identity build.
  ARM64 resolved four stages and x64 two stages. One target per binding and separate
  per-architecture promotion groups are required; see `CI.md`.

## Shell and assistant evidence

`smoke-shell.sh` starts an isolated D-Bus session, headless Chroma, PipeWire,
a real Wayland terminal and Lumina Shell. It checks the compositor connection,
window discovery, notifications and six panels, then executes the QML zoom
and window-close fixture. This caught and fixed the missing `action ` prefix
in the initial Chroma adapter.

Rendering passed at 1280x800, two 1280x800 outputs, and 1920x1200 at scale 2.
Screenshots were visually reviewed. The test session lacks UPower, so battery
hardware behavior is unverified. No QML errors remained in passing runs.

The assistant helper passed 11 distinct unittest cases. The QML integration
fixture configured a local simulated OpenAI-compatible provider, sent a chat
and verified the displayed response and mode-0600 settings. This caught and
fixed the initial configuration race. No paid provider credentials were used;
live cloud account compatibility and cancellation during a real cloud request
remain unqualified. Provider keys are neither printed nor passed in argv.

Evidence logs and screenshots are retained locally under
`desktop/evidence/local-20260911/`. This directory and `desktop/dist/` are
ignored by Git; the acceptance record and RPM hashes are committed.

## Media and remaining release work

`installer/build-iso.py` produces a network installer from a signed and
SHA-256-verified Fedora Everything 44 base ISO. Both architecture profiles
pass `ksvalidator -v F44`. The build preserves EFI loaders, reconstructs the
FAT image using mtools, and supplies a Lumina Anaconda product image.

The ARM64 development image is
`desktop/dist/Lumina-26.9-Cassiopeia-aarch64-development.iso`, with adjacent
ISO and package SHA-256 manifests. It requires network access for Fedora
packages. Earlier development media booted to the graphical Anaconda summary
under QEMU/KVM with EDK2 UEFI, loaded the package profile and displayed the
Lumina identity. Disk selection is interactive. The final account-profile
verification is recorded in the accompanying boot evidence below.

Anaconda treats any kickstarted root password command, including a locked
root account, as an administrator configuration. The final profile therefore
leaves account setup to the UI, hides the root-password spoke and locks root
in `%post`, so an administrator user must be created.

The generated Cassiopeia wallpaper is 1672x941 pixels; vector marks remain
scalable. A native 4K wallpaper is not claimed.

Remote execution now uses the verified project snapshot route over the
normal authenticated administration API. Both native projects are registered;
see `CI.md`. The earlier run used source `cd10d253517180880d1749d2920a7915de99b900`.
ARM64 delivery `549b68ef-db4d-442e-bc97-d3cbc60750d9` has built, scanned and
signed the six base packages other than Quickshell. Its Quickshell build
`5b546f3c-41fa-4c5b-abfc-512d5ab10bea` generated RPMs with two compiler jobs; all nine CTest suites passed.
The six completed packages were downloaded through the artifact API, checked
against their recorded SHA-256 digests and independently verified using
`rpmkeys --checksig --verbose` with the shipped Lumina public signing key.
The console subsequently marked this Quickshell job failed after 52m 11s:
`Kubernetes Pod does not belong to the recorded Job UID.` Scanning and signing
were skipped, and the other six packages' pending publication stages were
cancelled. The last captured runner log had reached artifact upload after the
successful compile and tests. No successful artifact ingestion or publication
is claimed for this run.

The x64 delivery `d2236f0a-1306-447f-ad97-666e7128b71c` was cancelled because
its runner selected an outdated private Qt ABI from the release-only Fedora
repository. Replacement delivery `93f430b5-2992-4b20-9660-361c6f4a235e` uses
the corrected runner with Fedora updates enabled. Its obsolete ten-package
plan is superseded by the three-package native manifest: noarch packages
are published once by ARM64 to avoid duplicate repository identities. x64
dispatch must wait for shared-package publication. At 16:52 UTC the local
ARM64 host had restarted and `k3s-agent` could not reach the cluster at
`10.77.0.1:6443`; SSH port 22 also timed out, while public console HTTPS and
the existing browser login remained available. The key was restored to the
SSH agent through KWallet. Retry the verified project matrix after cluster
connectivity is restored; do not bypass the Job UID provenance check.
These are interim build
observations, not release acceptance. The development ISO and local RPM hash
list above predate the font and Quickshell `2.lu26` packaging corrections.

## Earlier development boot-only evidence

The early development ISO booted to the Lumina-branded graphical Anaconda summary
under QEMU 10.2.2/KVM with EDK2 UEFI, four vCPUs, 4 GiB RAM and a new empty
24 GiB virtual disk. Fedora network source and the custom package selection
loaded successfully. Both disk selection and User Creation were marked
required; the root-password spoke was hidden and Begin Installation remained
disabled. No installation or disk partitioning was performed.

Screenshot and serial log:
`desktop/evidence/uefi-aarch64-final/{installer.png,serial.log}`.

ISO size: `1397030912` bytes. SHA-256:

`6397b0790ac0c6265b11dc61060751be1fd4809a2cc112fb4619b56978e82adf`
