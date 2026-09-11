#!/usr/bin/python3
"""Lorax EFI FAT-image helper for container builds without loop devices."""
import argparse
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--label', '-l', default='EFI')
parser.add_argument('bootdir', type=Path)
parser.add_argument('outfile', type=Path)
args = parser.parse_args()
if not args.bootdir.is_dir():
    parser.error('expected a boot directory')
if args.outfile.is_symlink() or (args.outfile.exists() and
        (not args.outfile.is_file() or args.outfile.stat().st_size != 0)):
    parser.error('output must be absent or an empty regular temporary file')
files = list(args.bootdir.iterdir())
if not any(p.name.startswith('BOOT') and p.suffix.upper() == '.EFI' for p in files):
    parser.error('boot directory has no EFI fallback loader')
args.outfile.unlink(missing_ok=True)
subprocess.run(['mkfs.fat', '-C', '-F', '32', '-n', args.label, str(args.outfile), '131072'], check=True)
subprocess.run(['mmd', '-i', str(args.outfile), '::/EFI', '::/EFI/BOOT'], check=True)
subprocess.run(['mcopy', '-s', '-i', str(args.outfile), *map(str, files), '::/EFI/BOOT/'], check=True)
