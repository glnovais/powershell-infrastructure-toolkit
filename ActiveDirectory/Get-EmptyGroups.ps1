<#
.SYNOPSIS
    Localiza grupos do Active Directory sem membros.
#>

[CmdletBinding()]
param(
    [string]$SearchBase,
    [string]$OutputPath = ".\EmptyGroups.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$params = @{
    Filter     = '*'
    Properties = @('Members', 'GroupCategory', 'GroupScope', 'Description')
}

if ($SearchBase) {
    $params.SearchBase = $SearchBase
}

Get-ADGroup @params |
    Where-Object { $_.Members.Count -eq 0 } |
    Select-Object Name,
                  SamAccountName,
                  GroupCategory,
                  GroupScope,
                  Description,
                  DistinguishedName |
    Sort-Object Name |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
