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
and the matching approved native build profile. These separate manifests
contain ten packages and no board packages. The main repository manifest
retains its existing ARM64 board targets. Generate the desktop manifests with
`python3 desktop/tools/desktop-manifests.py`; CI can use `--check` to detect drift.

Source pushes must go through the project webhook/snapshot route. The
standalone console pipeline trigger does not create the verified repository
snapshot required by the Kubernetes executor. Do not disable this check.
Both desktop manifests were passed through the actual
`ProjectDispatchPlanResolver` from the local LuminaCI checkout: each resolved
ten packages in four dependency stages. This validates planning, not execution.

Both repository projects were registered on 2026-09-11 with ten bindings each:

- ARM64: `2d6ba348-71a7-49d3-9ab3-e91d9302121c`
- x64: `d275186a-8b93-493c-a601-e0c89bfd1956`

The initial signed project deliveries (`5ebd7254-4f2e-40fa-b26f-e1b380192f0b`
and `ecd785b6-9722-46b2-8d1d-3fa0272910e9`) verified source commit `da64d62`
and dispatched native Kubernetes jobs. They exposed missing offline upstream
inputs: the runner intentionally sets `AUTO_DOWNLOAD=false`. The manifests now
register five pinned source archives as `lookaside_sources`. Upload each archive
through `/api/extra-sources/pipeline/{pipelineId}` with `subFolder=pipeline` for
both architecture bindings. CI verifies size and SHA-256 before sealing the
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
- `fedora-44-x86_64`: `registry.lumina.1t.ru/lumina-rpm-build@sha256:7d1b3de3f30585099fd8d2b89765d8816cf86293ffe11c7c523ddb08d2afc8e9`

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
