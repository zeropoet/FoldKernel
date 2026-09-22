#!/usr/bin/env bash
set -euo pipefail

destination=${1:?destination required}
test -d "$destination"

find "$destination" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cp index.html styles.css robots.txt sitemap.xml "$destination/"
install -d "$destination/Assets/Brand"
cp Assets/Brand/fold-kernel-mark.svg Assets/Brand/fold-kernel-mark.png "$destination/Assets/Brand/"
