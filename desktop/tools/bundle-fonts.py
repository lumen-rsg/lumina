#!/usr/bin/env python3
"""Bundle pinned upstream fonts and licenses for offline LuminaCI RPM builds."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import tarfile
import urllib.request

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('package', choices=['google-sans-flex-vf-fonts', 'google-material-symbols-vf-rounded-fonts'])
parser.add_argument('--source-dir', type=Path, help='Use an existing download cache instead of fetching upstream')
parser.add_argument('--check', action='store_true', help='Verify the committed archive against the pinned inventory')
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
package = root / 'desktop' / args.package
inventory = json.loads((package / 'sources.json').read_text())
archive = package / 'files' / f'{args.package}-20260911.tar.xz'
if args.check:
    with tarfile.open(archive) as bundle:
        assert sorted(bundle.getnames()) == sorted(item['file'] for item in inventory)
        for item in inventory:
            member = bundle.getmember(item['file'])
            assert member.isfile() and member.size == item['size']
            assert hashlib.sha256(bundle.extractfile(member).read()).hexdigest() == item['sha256']
else:
    content = []
    for item in inventory:
        if args.source_dir:
            data = (args.source_dir / item['file']).read_bytes()
        else:
            with urllib.request.urlopen(item['url'], timeout=120) as response:
                data = response.read(item['size'] + 1)
        if len(data) != item['size'] or hashlib.sha256(data).hexdigest() != item['sha256']:
            raise SystemExit(f"Upstream integrity mismatch: {item['file']}")
        content.append((item['file'], data))
    archive.parent.mkdir(exist_ok=True)
    with tarfile.open(archive, 'w:xz', format=tarfile.USTAR_FORMAT) as bundle:
        for name, data in sorted(content):
            member = tarfile.TarInfo(name)
            member.size = len(data)
            member.mode = 0o644
            member.mtime = 0
            bundle.addfile(member, io.BytesIO(data))
print(f'{hashlib.sha256(archive.read_bytes()).hexdigest()}  {archive.relative_to(root)} ({archive.stat().st_size} bytes)')
