# Inserts the Yandex.Games SDK bridge into the exported index.html and zips the build.
# Usage (from the project folder):
#   powershell -ExecutionPolicy Bypass -File .\_bin\patch_yandex.ps1

$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectDir 'build'
$indexPath = Join-Path $buildDir 'index.html'
$snippetPath = Join-Path $projectDir 'web\yandex_snippet.html'
$zipPath = Join-Path $projectDir 'slime_rush_yandex.zip'

if (-not (Test-Path $indexPath)) {
	Write-Host "NO BUILD: $indexPath not found. Export the Web preset into the build folder first."
	exit 1
}

$html = Get-Content $indexPath -Raw -Encoding UTF8
$snippet = Get-Content $snippetPath -Raw -Encoding UTF8

if ($html -like '*window.nlReady*') {
	Write-Host 'ALREADY PATCHED'
} else {
	$html = $html -replace '</head>', ($snippet + "</head>")
	Set-Content -Path $indexPath -Value $html -Encoding UTF8 -NoNewline
	Write-Host 'INDEX PATCHED'
}

if (Test-Path $zipPath) {
	Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $buildDir '*') -DestinationPath $zipPath
Write-Host "ZIP READY: $zipPath"
Write-Host ('SIZE MB: ' + [math]::Round(((Get-Item $zipPath).Length / 1MB), 2))
