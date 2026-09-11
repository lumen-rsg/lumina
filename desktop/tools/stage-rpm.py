#!/usr/bin/env python3
"""Stage a spec and its pinned sources in an isolated RPM tree.

Run inside a builder with rpmspec and the package's BuildRequires installed.
The spec's prep section checks upstream source SHA-256 before extraction.
"""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import urllib.parse
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument("spec", type=Path)
parser.add_argument("topdir", type=Path)
args = parser.parse_args()
spec = args.spec.resolve()
top = args.topdir.resolve()
for name in ["SOURCES", "SPECS", "BUILD", "BUILDROOT", "RPMS", "SRPMS"]:
    (top / name).mkdir(parents=True, exist_ok=True)
shutil.copyfile(spec, top / "SPECS" / spec.name)
expanded = subprocess.check_output(["rpmspec", "-P", str(spec)], text=True)
for value in re.findall(r"^(?:Source|Patch)\d*:\s*(.+)$", expanded, flags=re.M):
    url = urllib.parse.urlsplit(value)
    name = Path(url.fragment or url.path).name
    target = top / "SOURCES" / name
    candidates = [spec.parent / name, spec.parent / "files" / name]
    companion = next((p for p in candidates if p.is_file()), None)
    if companion:
        shutil.copyfile(companion, target)
    elif url.scheme == "https":
        request = urllib.request.Request(urllib.parse.urlunsplit(url._replace(fragment="")), headers={"User-Agent":"LuminaCI source staging"})
        with urllib.request.urlopen(request, timeout=120) as response, target.open("wb") as stream:
            shutil.copyfileobj(response, stream)
    else:
        raise SystemExit(f"Missing source {name} for {spec}")
    print(target)
