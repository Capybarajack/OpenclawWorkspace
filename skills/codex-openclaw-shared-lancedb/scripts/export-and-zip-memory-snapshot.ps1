param(
  [Parameter(Mandatory = $false)]
  [string]$SourceDbPath = (Join-Path $env:USERPROFILE ".openclaw\memory\lancedb-pro"),

  [Parameter(Mandatory = $false)]
  [string]$SnapshotRoot = (Join-Path $PSScriptRoot "..\assets\memory-snapshot"),

  [Parameter(Mandatory = $false)]
  [string]$ZipOutputDir = (Join-Path $PSScriptRoot "..\assets\memory-snapshot-zips")
)

$ErrorActionPreference = 'Stop'

$exportScript = Join-Path $PSScriptRoot 'export-memory-snapshot.ps1'
if (-not (Test-Path $exportScript)) {
  throw "export-memory-snapshot.ps1 not found at: $exportScript"
}

& $exportScript -SourceDbPath $SourceDbPath -OutputRoot $SnapshotRoot

if (-not (Test-Path $SnapshotRoot)) {
  throw "Snapshot root not found: $SnapshotRoot"
}

$latest = Get-ChildItem -Path $SnapshotRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
if (-not $latest) {
  throw "No snapshot folder found in: $SnapshotRoot"
}

if (-not (Test-Path $ZipOutputDir)) {
  New-Item -ItemType Directory -Force -Path $ZipOutputDir | Out-Null
}

$zipPath = Join-Path $ZipOutputDir ("{0}.zip" -f $latest.Name)
if (Test-Path $zipPath) {
  Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path $latest.FullName -DestinationPath $zipPath -Force

Write-Host "Zipped snapshot: $zipPath"
