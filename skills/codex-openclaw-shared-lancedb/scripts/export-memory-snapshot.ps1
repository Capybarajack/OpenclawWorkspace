param(
  [Parameter(Mandatory = $false)]
  [string]$SourceDbPath = (Join-Path $env:USERPROFILE ".openclaw\memory\lancedb-pro"),

  [Parameter(Mandatory = $false)]
  [string]$OutputRoot = (Join-Path $PSScriptRoot "..\assets\memory-snapshot")
)

$ErrorActionPreference = 'Stop'

function Get-DirAggregateHash {
  param([string]$Path)
  $files = Get-ChildItem -Path $Path -Recurse -File | Sort-Object FullName
  if (-not $files) { return '' }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    [void]$sha.TransformBlock($bytes, 0, $bytes.Length, $null, 0)
  }
  [void]$sha.TransformFinalBlock([byte[]]::new(0), 0, 0)
  return ([System.BitConverter]::ToString($sha.Hash) -replace '-', '').ToLowerInvariant()
}

$src = (Resolve-Path $SourceDbPath).Path
if (-not (Test-Path $src)) { throw "SourceDbPath not found: $SourceDbPath" }

if (-not (Test-Path $OutputRoot)) {
  New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
}

$outputRootResolved = (Resolve-Path $OutputRoot).Path
$version = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$snapshotDir = Join-Path $outputRootResolved $version
$dbDir = Join-Path $snapshotDir 'db'

New-Item -ItemType Directory -Force -Path $dbDir | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dbDir -Recurse -Force

$fileList = Get-ChildItem -Path $dbDir -Recurse -File
$totalBytes = ($fileList | Measure-Object Length -Sum).Sum
if (-not $totalBytes) { $totalBytes = 0 }

$manifest = [ordered]@{
  snapshotVersion = $version
  createdAt = (Get-Date).ToUniversalTime().ToString('o')
  sourceDbPath = $src
  fileCount = @($fileList).Count
  totalBytes = $totalBytes
  aggregateSha256 = (Get-DirAggregateHash -Path $dbDir)
}

$manifestPath = Join-Path $snapshotDir 'manifest.json'
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Snapshot created: $snapshotDir"
Write-Host "Version: $version"
Write-Host "Files: $($manifest.fileCount), Bytes: $($manifest.totalBytes)"
Write-Host "SHA256: $($manifest.aggregateSha256)"
