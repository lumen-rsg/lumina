#!/usr/bin/env python3
"""Fetch pinned, signature-checked RPM Fusion repository RPMs for Fedora 44."""
import argparse
import hashlib
from pathlib import Path
import subprocess
import tempfile
import urllib.request


RELEASES = {
    'free': '8af2dbb02e3a72f0961ec79cf1ea3f350719cb830b0f99f59e939389feb34b1c',
    'nonfree': 'c2606f494b0c4417bf6632f865448da3febb420e19182e47874d8db4c35a8a8e',
}
KEYS = Path(__file__).resolve().parent / 'branding/etc/pki/rpm-gpg'


def prepare(output):
    """Use upstream noarch RPMs on both architectures; never install drivers."""
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    result = []
    with tempfile.TemporaryDirectory(prefix='lumina-rpmfusion-') as temporary:
        work = Path(temporary)
        database = work / 'rpmdb'
        database.mkdir()
        for kind, expected in RELEASES.items():
            name = f'rpmfusion-{kind}-release-44-3.noarch.rpm'
            # Both repository packages are noarch; the x86_64 mirror directory
            # is only their download location, including for ARM64 composes.
            url = f'https://download1.rpmfusion.org/{kind}/fedora/updates/44/x86_64/r/{name}'
            target = output / name
            if target.exists():
                data = target.read_bytes()
            else:
                with urllib.request.urlopen(url, timeout=60) as response:
                    data = response.read()
            if hashlib.sha256(data).hexdigest() != expected:
                raise ValueError(f'RPM Fusion checksum mismatch: {name}')
            candidate = work / name
            candidate.write_bytes(data)
            key = KEYS / f'RPM-GPG-KEY-rpmfusion-{kind}-fedora-2020'
            subprocess.run(['rpmkeys', '--dbpath', str(database), '--import', str(key)], check=True)
            checked = subprocess.run(['rpmkeys', '--dbpath', str(database), '--checksig',
                                      str(candidate)], check=True, text=True, capture_output=True)
            if 'signatures OK' not in checked.stdout:
                raise ValueError(f'RPM Fusion signature check failed: {name}')
            target.write_bytes(data)
            result.append(target)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    for path in prepare(parser.parse_args().output):
        print(path)
