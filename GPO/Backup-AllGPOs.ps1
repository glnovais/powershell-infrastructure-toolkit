<#
.SYNOPSIS
    Realiza backup de todas as GPOs do domínio.
#>

[CmdletBinding()]
param(
    [string]$BackupPath = ".\GPO-Backup"
)

Import-Module GroupPolicy -ErrorAction Stop

New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$destination = Join-Path $BackupPath $timestamp

New-Item -ItemType Directory -Path $destination -Force | Out-Null

Backup-GPO -All -Path $destination

Write-Host "Backup concluído: $destination" -ForegroundColor Green
