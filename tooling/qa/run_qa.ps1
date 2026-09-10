# CurveFree local QA (Windows)
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $root

$env:PATH = "C:\flutter\bin;" + $env:PATH

Write-Host "== flutter analyze =="
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "== flutter test =="
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "== qa node deps =="
Set-Location (Join-Path $root "tooling/qa")
if (-not (Test-Path "node_modules")) {
  npm install
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  npx playwright install chromium
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "== playwright + lighthouse =="
npm run qa
exit $LASTEXITCODE
