#!/usr/bin/env bash
# Production web build for Vercel (PWA + go_router client routes).
set -euo pipefail

export PATH="${FLUTTER_HOME:-/vercel/flutter}/bin:$PATH"

echo "→ Resolving Dart dependencies"
flutter pub get

# Optional: inject Firebase web config from Vercel env (see docs/VERCEL_DEPLOY.md)
if [ -n "${FIREBASE_API_KEY:-}" ]; then
  echo "→ Generating firebase_options.dart from Vercel environment variables"
  dart run tool/generate_firebase_options.dart
fi

DART_DEFINES=(
  "--dart-define=DISPLAY_NAME=${DISPLAY_NAME:-Minusha}"
  "--dart-define=DAILY_CALORIE_GOAL=${DAILY_CALORIE_GOAL:-2000}"
)

if [ -n "${FOOD_VISION_API_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=FOOD_VISION_API_URL=${FOOD_VISION_API_URL}")
fi

echo "→ Building Flutter web (release)"
flutter build web \
  --release \
  --base-href / \
  "${DART_DEFINES[@]}"

echo "→ Build output: build/web ($(du -sh build/web | cut -f1))"
