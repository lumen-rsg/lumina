# Cassiopeia CI execution

The current LuminaCI project dispatcher requires **one target and one spec
owner per package binding**. A multi-target YAML entry is accepted by the
generic graph model but rejected by project dispatch. Use two desktop projects:

| Project | Manifest | Native profile | Promotion group |
| --- | --- | --- | --- |
| Cassiopeia ARM64 | `.lumina/desktop-aarch64.yaml` | `fedora-44-aarch64` | `cassiopeia-desktop-26.9-aarch64` |
| Cassiopeia x64 | `.lumina/desktop-x86_64.yaml` | `fedora-44-x86_64` | `cassiopeia-desktop-26.9-x86_64` |

Both projects use `https://github.com/lumen-rsg/lumina.git`, initially on
`codex/cassiopeia-desktop`. Bind every package ID in each manifest to its spec
and the matching approved native build profile. The ARM64 manifest
contains ten packages; x64 contains the three native packages (`quickshell`,
`chroma`, and `wl-clip-persist`). The `chroma` pipeline builds the
`chroma-compositor` RPM: Fedora's unrelated puzzle game already uses the
package name `chroma`. Neither includes board packages. The main repository manifest
retains its existing 26 package definitions and targets, including the x64
identity binding. Desktop definitions live in `.lumina/desktop-packages.yaml`;
only the two desktop projects consume the generated desktop manifests. Generate the desktop manifests with
`python3 desktop/tools/desktop-manifests.py`; CI can use `--check` to detect drift.

ARM64 is the canonical producer of the seven `noarch` RPMs. Both desktop
architectures install those exact shared artifacts from `lumen/noarch`.
Publishing separate native builds of a noarch package would collide on its
repository filename and NEVRA; LuminaCI intentionally rejects that operation.
Complete ARM64 publication first, then dispatch the x64 native project so its
promotion gate can resolve Lumina Shell from the published shared repository.
After x64 promotion, validate the complete `lumina-desktop` transaction in an
empty x64 install root, including the seven shared packages. The generator
selects native packages using RPM's expanded architecture metadata.

Source pushes must go through the project webhook/snapshot route. The
standalone console pipeline trigger does not create the verified repository
snapshot required by the Kubernetes executor. Do not disable this check.
Both desktop manifests were passed through the actual
`ProjectDispatchPlanResolver` from the local LuminaCI checkout: each resolved
ten ARM64 packages in four stages and three x64 packages in two stages.
This validates planning, not execution.

Both repository projects were registered on 2026-09-11. ARM64 has ten bindings;
x64 has three native bindings:

- ARM64: `2d6ba348-71a7-49d3-9ab3-e91d9302121c`
- x64: `d275186a-8b93-493c-a601-e0c89bfd1956`

The initial signed project deliveries (`5ebd7254-4f2e-40fa-b26f-e1b380192f0b`
and `ecd785b6-9722-46b2-8d1d-3fa0272910e9`) verified source commit `da64d62`
and dispatched native Kubernetes jobs. They exposed missing offline upstream
inputs: the runner intentionally sets `AUTO_DOWNLOAD=false`. The manifests now
register five pinned source archives as `lookaside_sources`. Upload each archive
through `/api/extra-sources/pipeline/{pipelineId}` with `subFolder=pipeline` for
each applicable architecture binding. CI verifies size and SHA-256 before sealing the
source into its content-addressed object store.

The font packages contain deterministic archives of their pinned font and
license files, built by `desktop/tools/bundle-fonts.py`. The unchanged upstream
URLs and digests are in each package's `sources.json`. Their release was bumped
to `2.lu26` for this source-packaging correction. Both revised font RPMs were
rebuilt locally. Verify source coverage before dispatch:

```sh
python3 desktop/tools/check-ci-sources.py
python3 desktop/tools/desktop-manifests.py --check
python3 desktop/tools/bundle-fonts.py google-sans-flex-vf-fonts --check
python3 desktop/tools/bundle-fonts.py google-material-symbols-vf-rounded-fonts --check
```

The native runners are pinned to these verified live profile references:

- `fedora-44-aarch64`: `registry.lumina.1t.ru/lumina-rpm-build@sha256:6c214c5199609f02b987a9aff877bf0ca3bd54bc7113b4f059753e6443969568`
- `fedora-44-x86_64`: `registry.lumina.1t.ru/lumina-rpm-build@sha256:6254d7fccefa0d58a33dbdfc1c396339a10baff2eda319f6d204c48f9b168aa9`

The x64 runner was corrected on 2026-09-11: its old image enabled only the
Fedora release repository and selected Qt 6.10.2, while current Fedora updates
and the ARM64 worker use Qt 6.11.2. The replacement overlays the old pinned
image with `scripts/build-rpm.sh`, `scripts/lumina-kubernetes-build`, and
`deploy/docker/lumina-fedora.repo` from LuminaCI commit
`171898eb3a8b2f10ade87775f039499d2bad3726`. Scripts are root-owned mode 0755;
the repository configuration is mode 0644. The overlay was built without
network access, imported into the native Kubernetes node and registered by
its immutable manifest digest in both the approved profile and x64
pipeline bindings. Fedora RPM signature verification remains enabled.

Quickshell limits compilation and Qt autogen to two concurrent jobs. The live
workers provide 2 CPUs and 4 GiB, while RPM initially counted 12 ARM host CPUs;
the native run reached the memory limit with over 4 GiB of anonymous memory.
The toolkit release is `2.lu26` for this build-resource correction.

Each pipeline builds, scans, signs with the active Lumina key, and stages for
`lumen` (`82886b10-0a9f-442a-a3fc-2e95afbaa254`). Native promotion gates must pass
before publication. Project credentials remain server-side. The initial
dispatch used administrator-signed webhook requests; recurring GitHub webhook
registration for these desktop projects still needs verification.

After native builds pass, use the existing scan, signing, candidate staging,
dependency-closure and repository promotion path for each architecture.
Quickshell's private Qt ABI dependency must resolve against the Qt version
available to desktop clients. Test the published repository in an empty
install root before composing signed release media. Record delivery/build IDs,
source commit, RPM signatures, repository URLs and artifact checksums in
`ACCEPTANCE.md`. Local unsigned RPMs are development artifacts.

## Independent shell releases

`.lumina/desktop-shell.yaml` selects only the architecture-independent shell,
using the approved ARM64 runner and the `cassiopeia-shell-26.9` promotion group.
Its dedicated project/pipeline keeps the usual source snapshot, scan, signing,
native dependency validation and publication gates. Runtime dependencies come
from the already published signed desktop repositories. Use the coordinated
manifests when compositor/toolkit or shared dependency versions change.

Do not redispatch the whole desktop group for a shell-only update: it rebuilds
unchanged package versions, and repository staging correctly rejects duplicate
NEVRAs. The September 18 aggregate attempt `3afa01db-8a7b-4eb1-86fe-24ce3167f918`
failed on this check before shell publication; it is not a release candidate.
