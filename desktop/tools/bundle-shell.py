#!/usr/bin/env python3
"""Reproducible source bundle consumed by LuminaCI's companion-source loader."""
import argparse
import gzip
import io
from pathlib import Path
import tarfile

root = Path(__file__).resolve().parents[1] / "lumina-shell"
parser = argparse.ArgumentParser()
parser.add_argument("--check", action="store_true")
args = parser.parse_args()
raw = io.BytesIO()
with tarfile.open(fileobj=raw, mode="w", format=tarfile.PAX_FORMAT) as archive:
    for path in sorted([root / "LICENSE", root / "CHROMA-LICENSE", root / "UPSTREAM.json"] + list((root / "shell").rglob("*"))):
        if not path.is_file(): continue
        info = archive.gettarinfo(str(path), arcname="lumina-shell-26.9/" + str(path.relative_to(root)))
        info.uid = info.gid = info.mtime = 0
        info.uname = info.gname = ""
        info.mode = 0o644
        with path.open("rb") as stream: archive.addfile(info, stream)
content = gzip.compress(raw.getvalue(), mtime=0)
target = root / "files/lumina-shell-26.9.tar.gz"
if args.check:
    if not target.exists() or target.read_bytes() != content:
        raise SystemExit("Shell bundle is stale; run desktop/tools/bundle-shell.py")
else:
    target.write_bytes(content)
print(target)
