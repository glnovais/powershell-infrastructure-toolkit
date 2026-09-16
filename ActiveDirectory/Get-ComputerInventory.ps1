<#
.SYNOPSIS
    Exporta inventário básico dos computadores cadastrados no Active Directory.
#>

[CmdletBinding()]
param(
    [string]$SearchBase,
    [string]$OutputPath = ".\ADComputerInventory.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$params = @{
    Filter     = '*'
    Properties = @(
        'Enabled',
        'DNSHostName',
        'IPv4Address',
        'OperatingSystem',
        'OperatingSystemVersion',
        'LastLogonDate',
        'PasswordLastSet',
        'Description'
    )
}

if ($SearchBase) {
    $params.SearchBase = $SearchBase
}

Get-ADComputer @params |
    Select-Object Name,
                  Enabled,
                  DNSHostName,
                  IPv4Address,
                  OperatingSystem,
                  OperatingSystemVersion,
                  LastLogonDate,
                  PasswordLastSet,
                  Description,
                  DistinguishedName |
    Sort-Object Name |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Inventário salvo em: $OutputPath" -ForegroundColor Green
