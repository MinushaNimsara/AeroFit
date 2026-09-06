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

# Apply direct JS safety patches to compiled main.dart.js to eliminate Safari TypeError / Null check crash:
$mainJsPath = Join-Path $root "web\main.dart.js"
$mainJsRaw = [System.IO.File]::ReadAllText($mainJsPath, [System.Text.Encoding]::UTF8)

# 1. Null-safe check on s.isNewUser in bwB (convertWebAdditionalUserInfo)
$mainJsRaw = $mainJsRaw -replace 'r=s\.isNewUser', 'r=s!=null?s.isNewUser:!1;if(s==null)s={profile:null,providerId:"password",username:null}'

# 2. Null-safe check on l.providerId in bwD (convertWebOAuthCredential)
$mainJsRaw = $mainJsRaw -replace 'if\(l==null\)return m(\r?\n|\s*)s=l\.providerId', 'if(l==null||l.providerId==null)return m;$1s=l.providerId'

# 3. Null-safe check on h.metadata in aFM (UserWeb constructor)
$mainJsRaw = $mainJsRaw -replace 'if\(h\.metadata\.creationTime!=null\)', 'if(h.metadata&&h.metadata.creationTime!=null)'
$mainJsRaw = $mainJsRaw -replace 'if\(h\.metadata\.lastSignInTime!=null\)', 'if(h.metadata&&h.metadata.lastSignInTime!=null)'

# 4. CRITICAL: Null-safe check on g=e.a(a.customData) in beQ (getFirebaseAuthException).
# In Dart, customData is declared as non-nullable JSAny, so dart2js emits e.a(a.customData).
# When customData is undefined (default in FirebaseError on Safari), e.a throws:
# TypeError: Instance of 'minified:IV': type 'minified:IV' is not a subtype of type 'minified:c2'.
$mainJsRaw = $mainJsRaw -replace 'g=e\.a\(a\.customData\)', 'g=a&&a.customData!=null&&t.e.b(a.customData)?e.a(a.customData):{}'

# 5. CRITICAL: Guard entry of beQ against non-c2 objects (e.g. minified:IV)
# beQ begins with e=t.e\ne.a(a). If a is a Dart error (IV), e.a(a) throws the exact subtype error.
$mainJsRaw = $mainJsRaw -replace '(\bbeQ\(a,b\)\{var s,[^;]+,e=t\.e\r?\n)e\.a\(a\)', '$1if(a==null||!t.e.b(a))return A.jl("unknown",f,f,A.o(a),f,f)'

# 6. CRITICAL: Guard EB (guardAuthExceptions) against non-c2 error casts:
# In EB catch(m): p=t.e.a(r). If r is a Dart error (minified:IV), t.e.a(r) throws.
$mainJsRaw = $mainJsRaw -replace 'p=t\.e\.a\(r\)', 'p=t.e.b(r)?r:m'

# 7. CRITICAL: Guard catchError callback in A.b_l:
# $2(a,b){var s=A.beQ(a,this.a)
$mainJsRaw = $mainJsRaw -replace '(\$2\(a,b\)\{)var s=A\.beQ\(a,this\.a\)', '$1var s=t.e.b(a)?A.beQ(a,this.a):A.jl("unknown",null,null,A.o(a),null,null)'

# 8. Guard OAuthProvider.credentialFromError in beQ:
$mainJsRaw = $mainJsRaw -replace 'if\(r!=null\)\{q=r\.providerId', 'if(r!=null&&r.providerId!=null){q=r.providerId'

[System.IO.File]::WriteAllText($mainJsPath, $mainJsRaw, [System.Text.Encoding]::UTF8)
Write-Host "Applied compiled JS patches to main.dart.js."

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
$v9Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV9Path = Join-Path $root "web\flutter_bootstrap_v9.js"
Set-Content -Path $bootstrapV9Path -Value $v9Bootstrap -NoNewline

$mainJs = Get-Item "web\main.dart.js"
$mainV9Path = Join-Path $root "web\main_v9.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV9Path -Force

# Also update v8, v7, v6, v5, v4, v3, and v2 files so any cached index.html works with updated code
$v8Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV8Path = Join-Path $root "web\flutter_bootstrap_v8.js"
Set-Content -Path $bootstrapV8Path -Value $v8Bootstrap -NoNewline
$mainV8Path = Join-Path $root "web\main_v8.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV8Path -Force

$v7Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV7Path = Join-Path $root "web\flutter_bootstrap_v7.js"
Set-Content -Path $bootstrapV7Path -Value $v7Bootstrap -NoNewline
$mainV7Path = Join-Path $root "web\main_v7.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV7Path -Force

$v6Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV6Path = Join-Path $root "web\flutter_bootstrap_v6.js"
Set-Content -Path $bootstrapV6Path -Value $v6Bootstrap -NoNewline
$mainV6Path = Join-Path $root "web\main_v6.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV6Path -Force

$v5Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV5Path = Join-Path $root "web\flutter_bootstrap_v5.js"
Set-Content -Path $bootstrapV5Path -Value $v5Bootstrap -NoNewline
$mainV5Path = Join-Path $root "web\main_v5.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV5Path -Force

$v4Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV4Path = Join-Path $root "web\flutter_bootstrap_v4.js"
Set-Content -Path $bootstrapV4Path -Value $v4Bootstrap -NoNewline
$mainV4Path = Join-Path $root "web\main_v4.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV4Path -Force

$v3Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV3Path = Join-Path $root "web\flutter_bootstrap_v3.js"
Set-Content -Path $bootstrapV3Path -Value $v3Bootstrap -NoNewline
$mainV3Path = Join-Path $root "web\main_v3.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV3Path -Force

$v2Bootstrap = $bootstrap -replace '"mainJsPath"\s*:\s*"main\.dart\.js"', '"mainJsPath":"main_v9.dart.js"'
$bootstrapV2Path = Join-Path $root "web\flutter_bootstrap_v2.js"
Set-Content -Path $bootstrapV2Path -Value $v2Bootstrap -NoNewline
$mainV2Path = Join-Path $root "web\main_v2.dart.js"
Copy-Item -Path $mainJs.FullName -Destination $mainV2Path -Force

# Point index.html to flutter_bootstrap_v9.js
$indexContent = Get-Content $indexPath -Raw
$indexContent = $indexContent -replace 'src="flutter_bootstrap[^"]*"', 'src="flutter_bootstrap_v9.js"'
Set-Content -Path $indexPath -Value $indexContent -NoNewline

# ALSO sync to build/web because Vercel project has Root Directory = build/web
Copy-Item -Path "web\*" -Destination "build\web\" -Recurse -Force

Write-Host "Web build ready in web/ and build/web/ (main.dart.js: $($mainJs.Length) bytes, created main_v9.dart.js & flutter_bootstrap_v9.js)"
