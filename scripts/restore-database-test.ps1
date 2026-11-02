param(
  [Parameter(Mandatory = $true)]
  [string]$BackupPath,

  [Parameter(Mandatory = $true)]
  [switch]$IUnderstandThisErasesTargetDatabase
)

$ErrorActionPreference = 'Stop'
$productionRef = 'xfzkfhxdrotczbsxxztr'

if (-not $IUnderstandThisErasesTargetDatabase) {
  throw 'La restauración requiere confirmación explícita.'
}
if ($env:ASE_RESTORE_CONFIRMATION -ne 'ASE-WORK-TEST-RESTORE') {
  throw 'Define ASE_RESTORE_CONFIRMATION=ASE-WORK-TEST-RESTORE para confirmar que el destino es de pruebas.'
}
if (-not $env:ASE_BACKUP_DATABASE_URL -or -not $env:ASE_RESTORE_DATABASE_URL) {
  throw 'Define ASE_BACKUP_DATABASE_URL y ASE_RESTORE_DATABASE_URL fuera del proyecto.'
}
if ($env:ASE_RESTORE_DATABASE_URL -match $productionRef) {
  throw 'El destino coincide con el proyecto de producción bloqueado.'
}

function Get-SafeDatabaseIdentity([string]$ConnectionString) {
  $uri = [System.Uri]$ConnectionString
  $user = if ($uri.UserInfo) { ($uri.UserInfo -split ':', 2)[0] } else { '' }
  return "$($uri.Scheme)://$user@$($uri.Host):$($uri.Port)$($uri.AbsolutePath)"
}

$sourceIdentity = Get-SafeDatabaseIdentity $env:ASE_BACKUP_DATABASE_URL
$targetIdentity = Get-SafeDatabaseIdentity $env:ASE_RESTORE_DATABASE_URL
if ($sourceIdentity -eq $targetIdentity) {
  throw 'Origen y destino son la misma base. Restauración cancelada.'
}

$resolvedBackup = [System.IO.Path]::GetFullPath($BackupPath)
if (-not (Test-Path -LiteralPath $resolvedBackup -PathType Leaf)) {
  throw 'No existe el archivo de copia indicado.'
}

$restore = Get-Command pg_restore -ErrorAction SilentlyContinue
if (-not $restore) { throw 'Se necesita pg_restore de PostgreSQL.' }

& $restore.Source --list $resolvedBackup | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'El archivo no es una copia válida para pg_restore.' }

& $restore.Source --dbname=$env:ASE_RESTORE_DATABASE_URL --clean --if-exists --no-owner --no-privileges --exit-on-error $resolvedBackup
if ($LASTEXITCODE -ne 0) { throw 'La restauración de prueba no terminó correctamente.' }

[pscustomobject]@{
  Restored = $true
  Target = $targetIdentity
  Backup = $resolvedBackup
}
