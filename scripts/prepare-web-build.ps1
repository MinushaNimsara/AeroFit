# Builds AeroFit web and syncs output into web/ for Vercel.
# Deletes stale main.dart.js so Flutter cannot reuse an old bundle.
#
# IMPORTANT: do NOT use --wasm here. dart2wasm does not reliably bake
# --dart-define values (e.g. GEMINI_API_KEY) into main.dart.wasm, and modern
# browsers prefer the wasm build when it is listed first — which produced
# empty-key 403s for meal analysis. JS/canvaskit gets the defines correctly.
#
# Do NOT pass --no-web-resources-cdn: it skips downloading a fresh,
# engine-matched CanvasKit build and silently reuses whatever old
# web/canvaskit/* happens to be on disk (or committed to git).

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Set-Location $root

Remove-Item -Recurse -Force ".dart_tool\flutter_build" -ErrorAction SilentlyContinue

Remove-Item -Force "web\main.dart.js" -ErrorAction SilentlyContinue

Remove-Item -Force "web\flutter_bootstrap.js" -ErrorAction SilentlyContinue

# Remove any previous wasm artifacts so browsers cannot pick a stale empty-key build.
Remove-Item -Force "web\main.dart.wasm","web\main.dart.mjs","build\web\main.dart.wasm","build\web\main.dart.mjs" -ErrorAction SilentlyContinue

# build/web is never touched by `flutter build web` for files it considers already present,
# so a stale CanvasKit (mismatched engine revision vs a freshly compiled main.dart.js)
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

if (-not [string]::IsNullOrWhiteSpace($env:GEMINI_MODEL)) {
  $geminiDefine += "--dart-define=GEMINI_MODEL=$($env:GEMINI_MODEL)"
}

flutter build web --release --base-href / --no-wasm-dry-run @geminiDefine

$cacheJs = Get-ChildItem ".dart_tool\flutter_build" -Recurse -Filter "main.dart.js" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

Copy-Item -Path "build\web\*" -Destination "web\" -Recurse -Force

if ($null -ne $cacheJs) {
  Copy-Item -Path $cacheJs.FullName -Destination "web\main.dart.js" -Force
}

# Ensure no leftover wasm entry can be served from a previous --wasm build.
Remove-Item -Force "web\main.dart.wasm","web\main.dart.mjs" -ErrorAction SilentlyContinue

$sw = Join-Path web "flutter_service_worker.js"

if (Test-Path $sw) { Remove-Item $sw -Force }

$bootstrapPath = Join-Path $root "web\flutter_bootstrap.js"

$bootstrap = Get-Content $bootstrapPath -Raw

if ($bootstrap -notmatch '_flutter\.buildConfig\s*=') {
  throw "flutter_bootstrap.js is missing _flutter.buildConfig after build."
}

if ($bootstrap -match '"compileTarget"\s*:\s*"dart2wasm"') {
  throw "flutter_bootstrap.js unexpectedly includes a dart2wasm build (JS-only build required for GEMINI_API_KEY)."
}

if ($bootstrap -notmatch '"compileTarget"\s*:\s*"dart2js"') {
  throw "flutter_bootstrap.js is missing the dart2js/canvaskit build entry."
}

if ($bootstrap -match '\{\{flutter_') {
  throw "flutter_bootstrap.js still has unresolved template placeholders."
}

$buildTimestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

# Remove serviceWorkerSettings so flutter.js NEVER registers or tries to load a service worker
$bootstrap = $bootstrap -replace 'serviceWorkerSettings:\s*\{[^}]*\}', ''

# Generate standard flutter_bootstrap.js
$stdBootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', "`"mainJsPath`":`"main.dart.js?v=$buildTimestamp`""
Set-Content -Path $bootstrapPath -Value $stdBootstrap -NoNewline

# Generate completely new versioned filenames to 100% bypass all Vercel/Safari caches
$v5Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v5.dart.js"'
$bootstrapV5Path = Join-Path $root "web\flutter_bootstrap_v5.js"
Set-Content -Path $bootstrapV5Path -Value $v5Bootstrap -NoNewline

$mainJs = Get-Item "web\main.dart.js"
$mainV5Path = Join-Path $root "web\main_v5.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV5Path -Force

# Also update v4, v3, and v2 files so any cached index.html works with updated code
$v4Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v5.dart.js"'
$bootstrapV4Path = Join-Path $root "web\flutter_bootstrap_v4.js"
Set-Content -Path $bootstrapV4Path -Value $v4Bootstrap -NoNewline
$mainV4Path = Join-Path $root "web\main_v4.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV4Path -Force

$v3Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v5.dart.js"'
$bootstrapV3Path = Join-Path $root "web\flutter_bootstrap_v3.js"
Set-Content -Path $bootstrapV3Path -Value $v3Bootstrap -NoNewline
$mainV3Path = Join-Path $root "web\main_v3.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV3Path -Force

$v2Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v5.dart.js"'
$bootstrapV2Path = Join-Path $root "web\flutter_bootstrap_v2.js"
Set-Content -Path $bootstrapV2Path -Value $v2Bootstrap -NoNewline
$mainV2Path = Join-Path $root "web\main_v2.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV2Path -Force

# Point index.html to flutter_bootstrap_v5.js
$indexContent = Get-Content $indexPath -Raw
$indexContent = $indexContent -replace 'src="flutter_bootstrap[^"]*"', 'src="flutter_bootstrap_v5.js"'
Set-Content -Path $indexPath -Value $indexContent -NoNewline

# ALSO sync to build/web because Vercel project has Root Directory = build/web
Copy-Item -Path "web\*" -Destination "build\web\" -Recurse -Force

Write-Host "Web build ready in web/ and build/web/ (main.dart.js: $($mainJs.Length) bytes, created main_v5.dart.js & flutter_bootstrap_v5.js)"
