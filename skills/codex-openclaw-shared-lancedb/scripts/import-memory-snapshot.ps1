param(
  [Parameter(Mandatory = $true)]
  [string]$SnapshotDir,

  [Parameter(Mandatory = $false)]
  [string]$TargetDbPath = (Join-Path $env:USERPROFILE ".codex\memory\openclaw-lancedb-pro"),

  [switch]$NoBackup
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

$snapshot = (Resolve-Path $SnapshotDir).Path
$manifestPath = Join-Path $snapshot 'manifest.json'
$dbDir = Join-Path $snapshot 'db'

if (-not (Test-Path $manifestPath)) { throw "manifest.json not found in snapshot: $snapshot" }
if (-not (Test-Path $dbDir)) { throw "db directory not found in snapshot: $snapshot" }

$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
$currentHash = Get-DirAggregateHash -Path $dbDir
if ($manifest.aggregateSha256 -ne $currentHash) {
  throw "Snapshot checksum mismatch. expected=$($manifest.aggregateSha256), actual=$currentHash"
}

$target = $TargetDbPath
$parent = Split-Path -Path $target -Parent
if ($parent -and -not (Test-Path $parent)) {
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

if (Test-Path $target) {
  if (-not $NoBackup) {
    $backupPath = "$target.bak-" + (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    Move-Item -Path $target -Destination $backupPath -Force
    Write-Host "Backup created: $backupPath"
  } else {
    Remove-Item -Path $target -Recurse -Force
  }
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path (Join-Path $dbDir '*') -Destination $target -Recurse -Force

Write-Host "Snapshot imported to: $target"
Write-Host "Version: $($manifest.snapshotVersion)"
Write-Host "CreatedAt: $($manifest.createdAt)"
Write-Host "Files: $($manifest.fileCount), Bytes: $($manifest.totalBytes)"
