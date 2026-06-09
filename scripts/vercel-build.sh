#!/usr/bin/env bash
set -euo pipefail

if [ -f web/main.dart.js ] && [ -f web/index.html ]; then
  echo "→ Using committed web/ build output"
  exit 0
fi

if [ -f dist/main.dart.js ]; then
  echo "→ Copying dist/ into web/"
  rm -rf web
  mkdir -p web
  cp -r dist/. web/
  exit 0
fi

echo "ERROR: No Flutter web build found. Commit web/ or dist/ before deploying."
exit 1
