#!/usr/bin/env bash
set -euo pipefail

if [ ! -f build/web/main.dart.js ]; then
  echo "ERROR: build/web/main.dart.js is missing."
  echo "Run: flutter build web --release --base-href /"
  exit 1
fi

rm -rf dist
mkdir -p dist
cp -r build/web/. dist/
echo "Prepared dist/ from build/web ($(du -sh dist | cut -f1))"
