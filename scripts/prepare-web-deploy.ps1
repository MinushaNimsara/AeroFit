# Build Flutter web and sync output to committed web/ for Vercel.

$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot\..



$bootstrapTemplate = Join-Path $PSScriptRoot "flutter_bootstrap.js.tmpl"

Copy-Item -Path $bootstrapTemplate -Destination "web\flutter_bootstrap.js" -Force



flutter build web --release --base-href / --pwa-strategy none --no-web-resources-cdn



Copy-Item -Path build\web\* -Destination web\ -Recurse -Force



$sw = Join-Path web "flutter_service_worker.js"

if (Test-Path $sw) { Remove-Item $sw -Force }



Write-Host "web/ ready for Vercel ($(Get-ChildItem web -Recurse -File | Measure-Object).Count files)"


