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

The signed-in console was verified on 2026-09-11. The created
`cassiopeia-quickshell-aarch64` pipeline may be reused as its project binding.
Its first [remote attempt](https://console.lumina.1t.ru/builds/cf9caeb7-4e44-4d53-8794-60b420d3918c)
failed before execution with “Kubernetes builds require a verified
repository-project snapshot.” No artifact was built or published by that run.
The console currently exposes no project-management screen. A configured API
connection or working administration SSH endpoint is needed to register the
project bindings and dispatch the two matrices. SSH port 22 timed out during
this run; browser authentication itself succeeded.

After native builds pass, use the existing scan, signing, candidate staging,
dependency-closure and repository promotion path for each architecture.
Quickshell's private Qt ABI dependency must resolve against the Qt version
available to desktop clients. Test the published repository in an empty
install root before composing signed release media. Record delivery/build IDs,
source commit, RPM signatures, repository URLs and artifact checksums in
`ACCEPTANCE.md`. Local unsigned RPMs are development artifacts.
