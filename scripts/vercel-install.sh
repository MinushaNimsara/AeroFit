#!/usr/bin/env bash
# Installs Flutter SDK on Vercel's Linux build image (cached via FLUTTER_HOME).
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-/vercel/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [ ! -f "$FLUTTER_HOME/bin/flutter" ]; then
  echo "→ Cloning Flutter ($FLUTTER_CHANNEL) into $FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    --branch "$FLUTTER_CHANNEL" \
    "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version
flutter config --enable-web --no-analytics
flutter precache --web
