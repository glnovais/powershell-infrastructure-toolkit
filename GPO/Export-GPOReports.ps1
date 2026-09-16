<#
.SYNOPSIS
    Exporta relatórios HTML e XML de todas as GPOs.
#>

[CmdletBinding()]
param(
    [string]$OutputDirectory = ".\GPO-Reports"
)

Import-Module GroupPolicy -ErrorAction Stop

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Get-GPO -All | ForEach-Object {
    $safeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $html = Join-Path $OutputDirectory "$safeName.html"
    $xml  = Join-Path $OutputDirectory "$safeName.xml"

    Get-GPOReport -Guid $_.Id -ReportType Html -Path $html
    Get-GPOReport -Guid $_.Id -ReportType Xml  -Path $xml

    Write-Host "Exportado: $($_.DisplayName)" -ForegroundColor Cyan
}

Write-Host "Relatórios salvos em: $OutputDirectory" -ForegroundColor Green
