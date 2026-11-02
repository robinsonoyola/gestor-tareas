param(
  [Parameter(Mandatory = $true)]
  [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

if (-not $env:ASE_BACKUP_DATABASE_URL) {
  throw 'Define ASE_BACKUP_DATABASE_URL sin guardarla en archivos del proyecto.'
}

$dump = Get-Command pg_dump -ErrorAction SilentlyContinue
$restore = Get-Command pg_restore -ErrorAction SilentlyContinue
if (-not $dump -or -not $restore) {
  throw 'Se necesitan pg_dump y pg_restore de PostgreSQL.'
}

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $resolvedOutput | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = Join-Path $resolvedOutput "ase-work-$stamp.dump"
$hashPath = "$backupPath.sha256"

& $dump.Source --dbname=$env:ASE_BACKUP_DATABASE_URL --format=custom --compress=9 --no-owner --no-privileges --file=$backupPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $backupPath)) {
  throw 'No se pudo crear la copia de PostgreSQL.'
}

$listing = & $restore.Source --list $backupPath
if ($LASTEXITCODE -ne 0 -or -not $listing -or ($listing -join "`n") -notmatch 'TABLE') {
  Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
  throw 'La copia se creó, pero pg_restore no pudo validarla.'
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $backupPath).Hash
Set-Content -LiteralPath $hashPath -Encoding ascii -Value "$hash  $([System.IO.Path]::GetFileName($backupPath))"

[pscustomobject]@{
  Backup = $backupPath
  Sha256 = $hash
  Bytes = (Get-Item -LiteralPath $backupPath).Length
  Validated = $true
}
