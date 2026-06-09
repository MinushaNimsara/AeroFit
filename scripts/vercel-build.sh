#!/bin/sh
if [ -f web/main.dart.js ]; then
  echo "Using committed web/ output"
  exit 0
fi
if [ -f dist/main.dart.js ]; then
  rm -rf web
  mkdir -p web
  cp -r dist/. web/
  echo "Copied dist/ to web/"
  exit 0
fi
echo "ERROR: missing web/main.dart.js"
exit 1
