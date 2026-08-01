# Builds AeroFit web and syncs output into web/ for Vercel.
# Deletes stale main.dart.js so Flutter cannot reuse an old bundle.
# Uses --wasm so capable browsers get the dart2wasm/skwasm build, with an
# automatic dart2js/canvaskit fallback for browsers that can't run wasm GC.
# (A custom flutter_bootstrap.js template previously forced a single
# dart2js/canvaskit-only build, which triggers a CanvasKit/engine version
# mismatch ("PathBuilder is not a constructor") on some mobile GPUs. Letting
# Flutter generate its own bootstrap avoids that.)
# Do NOT pass --no-web-resources-cdn: it skips downloading a fresh,
# engine-matched CanvasKit build and silently reuses whatever old
# web/canvaskit/* happens to be on disk (or committed to git), which is
# exactly what causes that CanvasKit/engine mismatch.

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Set-Location $root

Remove-Item -Recurse -Force ".dart_tool\flutter_build" -ErrorAction SilentlyContinue

Remove-Item -Force "web\main.dart.js" -ErrorAction SilentlyContinue

Remove-Item -Force "web\flutter_bootstrap.js" -ErrorAction SilentlyContinue

# build/web is never touched by `flutter build web` for files it considers already present,
# so a stale CanvasKit (mismatched engine revision vs a freshly compiled main.dart.js/.wasm)
# can silently persist across many builds. Force a full re-fetch every time.

Remove-Item -Recurse -Force "build\web" -ErrorAction SilentlyContinue

Remove-Item -Recurse -Force "web\canvaskit" -ErrorAction SilentlyContinue

# The build's own output (copied back into web/ below) resolves this placeholder to a concrete
# value, so it must be restored before every build or `flutter build web` fails with
# "Couldn't find the placeholder for base href".

$indexPath = Join-Path $root "web\index.html"

$indexHtml = Get-Content $indexPath -Raw

$indexHtml = $indexHtml -replace '<base href="[^"]*">', '<base href="$FLUTTER_BASE_HREF">'

Set-Content -Path $indexPath -Value $indexHtml -NoNewline

# Optional meal-analysis key. Prefer an already-exported GEMINI_API_KEY env var;
# never hardcode the key in this script or in source.
$geminiDefine = @()
if (-not [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
  $geminiDefine += "--dart-define=GEMINI_API_KEY=$($env:GEMINI_API_KEY)"
  Write-Host "Building with GEMINI_API_KEY from environment."
} else {
  Write-Host "WARNING: GEMINI_API_KEY not set - meal photo analysis will fail in this build."
}

flutter build web --release --wasm --base-href / @geminiDefine

$cacheJs = Get-ChildItem ".dart_tool\flutter_build" -Recurse -Filter "main.dart.js" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

Copy-Item -Path "build\web\*" -Destination "web\" -Recurse -Force

if ($null -ne $cacheJs) {
  Copy-Item -Path $cacheJs.FullName -Destination "web\main.dart.js" -Force
}

$sw = Join-Path web "flutter_service_worker.js"

if (Test-Path $sw) { Remove-Item $sw -Force }

# Verify the generated bootstrap has a buildConfig with both the wasm and JS-fallback builds.

$bootstrapPath = Join-Path $root "web\flutter_bootstrap.js"

$bootstrap = Get-Content $bootstrapPath -Raw

if ($bootstrap -notmatch '_flutter\.buildConfig\s*=') {
  throw "flutter_bootstrap.js is missing _flutter.buildConfig after build."
}

if ($bootstrap -notmatch 'dart2wasm') {
  throw "flutter_bootstrap.js is missing the dart2wasm/skwasm build entry after build."
}

if ($bootstrap -match '\{\{flutter_') {
  throw "flutter_bootstrap.js still has unresolved template placeholders."
}

$mainJs = Get-Item "web\main.dart.js"
$mainWasm = Get-Item "web\main.dart.wasm"

Write-Host "Web build ready in web/ (main.dart.js: $($mainJs.Length) bytes, main.dart.wasm: $($mainWasm.Length) bytes)"
