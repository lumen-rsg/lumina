#!/usr/bin/env python3
"""Check that offline CI can obtain every desktop RPM Source and Patch input."""
from pathlib import Path
import re
import subprocess
import urllib.parse
import yaml

root = Path(__file__).resolve().parents[2]
graph = yaml.safe_load((root / '.lumina/desktop-aarch64.yaml').read_text())
for name, package in graph['packages'].items():
    spec = root / package['spec']
    expanded = subprocess.check_output(['rpmspec', '-P', str(spec)], text=True)
    lookaside = {item['file']: item for item in package.get('lookaside_sources', [])}
    used = set()
    count = 0
    for value in re.findall(r'^(?:Source|Patch)\d*:\s*(.+)$', expanded, flags=re.M):
        url = urllib.parse.urlsplit(value)
        filename = Path(url.fragment or url.path).name
        count += 1
        if any(p.is_file() for p in [spec.parent / filename, spec.parent / 'files' / filename]):
            if filename in lookaside:
                raise SystemExit(f'{name}: {filename} is both a companion file and a lookaside input')
            continue
        entry = lookaside.get(filename)
        if entry is None:
            raise SystemExit(f'{name}: {filename} is unavailable to the offline runner')
        if entry['size'] <= 0 or not re.fullmatch('[0-9a-f]{64}', entry['sha256']):
            raise SystemExit(f'{name}: {filename} has invalid immutable metadata')
        if entry['sha256'] not in expanded:
            raise SystemExit(f'{name}: {filename} needs an explicit digest check in the spec')
        used.add(filename)
    if used != lookaside.keys():
        raise SystemExit(f'{name}: unused lookaside entries: {lookaside.keys() - used}')
    print(f'{name}: {count} offline source inputs accounted for')
