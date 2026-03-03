#!/bin/bash
# Lumina GTK Icon Cache Updater
# Reads modified icon directories from stdin and updates their caches.

if ! command -v gtk-update-icon-cache &>/dev/null; then
    exit 0
fi

while read -r path; do
    # Remove the trailing filename to get the directory
    dir="/${path%/*}"
    
    # Only run if it's a directory and contains an index.theme
    if [[ -d "$dir" && -f "$dir/index.theme" ]]; then
        gtk-update-icon-cache -q -t -f "$dir" || true
    fi
done