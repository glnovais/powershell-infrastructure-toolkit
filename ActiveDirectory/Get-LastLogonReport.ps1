<#
.SYNOPSIS
    Gera relatório de último logon dos usuários do Active Directory.
#>

[CmdletBinding()]
param(
    [string]$SearchBase,
    [string]$OutputPath = ".\LastLogonReport.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$params = @{
    Filter     = '*'
    Properties = @('Enabled', 'LastLogonDate', 'PasswordLastSet', 'Description')
}

if ($SearchBase) {
    $params.SearchBase = $SearchBase
}

Get-ADUser @params |
    Select-Object Name,
                  SamAccountName,
                  Enabled,
                  LastLogonDate,
                  PasswordLastSet,
                  Description |
    Sort-Object LastLogonDate -Descending |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
