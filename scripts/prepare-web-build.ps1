# Builds AeroFit web and syncs output into web/ for Vercel.

# Deletes stale main.dart.js so Flutter cannot reuse an old bundle.



$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Set-Location $root



$bootstrapTemplate = Join-Path $PSScriptRoot "flutter_bootstrap.js.tmpl"



Remove-Item -Recurse -Force ".dart_tool\flutter_build" -ErrorAction SilentlyContinue

Remove-Item -Force "web\main.dart.js" -ErrorAction SilentlyContinue



# Flutter reads web/flutter_bootstrap.js as the bootstrap template (must contain placeholders).

Copy-Item -Path $bootstrapTemplate -Destination "web\flutter_bootstrap.js" -Force



flutter build web --release --base-href / --pwa-strategy none --no-wasm-dry-run --no-web-resources-cdn



$cacheJs = Get-ChildItem ".dart_tool\flutter_build" -Recurse -Filter "main.dart.js" |

  Sort-Object LastWriteTime -Descending |

  Select-Object -First 1



if ($null -eq $cacheJs) {

  throw "dart2js output not found after build."

}



Copy-Item -Path "build\web\*" -Destination "web\" -Recurse -Force

Copy-Item -Path $cacheJs.FullName -Destination "web\main.dart.js" -Force



$sw = Join-Path web "flutter_service_worker.js"

if (Test-Path $sw) { Remove-Item $sw -Force }



# Verify the generated bootstrap still has buildConfig from Flutter's template pass.

$bootstrapPath = Join-Path $root "web\flutter_bootstrap.js"

$bootstrap = Get-Content $bootstrapPath -Raw

if ($bootstrap -notmatch '_flutter\.buildConfig\s*=') {

  throw "flutter_bootstrap.js is missing _flutter.buildConfig after build."

}

if ($bootstrap -match '\{\{flutter_') {

  throw "flutter_bootstrap.js still has unresolved template placeholders."

}



Write-Host "Web build ready in web/ ($($cacheJs.Length) bytes)"


