#!/usr/bin/env python3
"""Download a complete Mesa desktop closure using an empty RPM database.

Run on the matching Fedora 44 architecture. The compose step independently
checks every RPM signature and records its digest before placing it on media.
"""
import argparse
import importlib.util
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--arch', choices=['aarch64', 'x86_64'], required=True)
    parser.add_argument('--rpms', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.rpms = args.rpms.resolve()
    args.output = args.output.resolve()
    if args.output.exists() and any(args.output.iterdir()):
        parser.error('output must be empty; do not mix package snapshots')
    args.output.mkdir(parents=True, exist_ok=True)
    spec = importlib.util.spec_from_file_location('builder', Path(__file__).with_name('build-iso.py'))
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    text = builder.render_kickstart(args.arch)
    block = text.split('%packages', 1)[1].split('%end', 1)[0]
    selected = [line for line in block.splitlines()[1:]
                if line and not line.startswith(('#', '-', '@^'))]
    subprocess.run(['createrepo_c', str(args.rpms)], check=True)
    with tempfile.TemporaryDirectory(prefix='lumina-offline-', dir=args.output.parent) as tmp:
        work = Path(tmp)
        repos = work/'repos'
        repos.mkdir()
        (repos/'compose.repo').write_text(f'''[base]
name=Lumina base packages
baseurl=https://dl.fedoraproject.org/pub/fedora/linux/releases/44/Everything/{args.arch}/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-44-primary

[updates]
name=Lumina base updates
baseurl=https://dl.fedoraproject.org/pub/fedora/linux/updates/44/Everything/{args.arch}/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-44-primary

[lumina-compose]
name=Lumina signed desktop snapshot
baseurl={args.rpms.as_uri()}
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-lumina-2026
''')
        subprocess.run(['dnf', '-y', '--releasever=44', '--installroot='+str(work/'root'),
                        '--setopt=reposdir='+str(repos), '--setopt=install_weak_deps=False',
                        '--setopt=keepcache=True', '--setopt=optional_metadata_types=comps',
                        '--setopt=destdir='+str(args.output), 'install', '--downloadonly',
                        *selected], check=True)
    print(f'Offline RPM closure: {args.output}')


if __name__ == '__main__':
    main()
