# Jetson build inputs

`l4t-r39.2-source-set.sha256` records the immutable NVIDIA L4T payloads used by
the Fedora RPM build. LuminaCI verifies these checksums while sealing the
lookaside sources declared in `.lumina/packages.yaml` before dispatching the
coherent `jetson-r39.2` promotion group.
