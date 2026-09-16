<#
.SYNOPSIS
    Lista usuários desabilitados no Active Directory.
#>

[CmdletBinding()]
param(
    [string]$SearchBase,
    [string]$OutputPath = ".\DisabledUsers.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$params = @{
    Filter     = 'Enabled -eq $false'
    Properties = @('LastLogonDate', 'Description', 'DistinguishedName')
}

if ($SearchBase) {
    $params.SearchBase = $SearchBase
}

Get-ADUser @params |
    Select-Object Name,
                  SamAccountName,
                  LastLogonDate,
                  Description,
                  DistinguishedName |
    Sort-Object Name |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
