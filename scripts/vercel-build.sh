#!/usr/bin/env bash
# Copy pre-built Flutter web bundle into web/ for Vercel output.
set -euo pipefail

if [ ! -f dist/main.dart.js ]; then
  echo "ERROR: dist/main.dart.js not found in repository."
  echo "Run locally: flutter build web --release --base-href /"
  echo "Then: bash scripts/prepare-vercel-dist.sh && git add dist && git push"
  exit 1
fi

rm -rf web
mkdir -p web
cp -r dist/. web/

echo "→ Prepared Vercel output in web/ ($(du -sh web | cut -f1))"
ls -la web | head -15
