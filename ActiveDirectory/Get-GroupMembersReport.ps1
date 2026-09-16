<#
.SYNOPSIS
    Exporta os membros dos grupos informados.
.EXAMPLE
    .\Get-GroupMembersReport.ps1 -GroupName "GRP_EXEMPLO","GRP_TI"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$GroupName,

    [string]$OutputPath = ".\GroupMembers.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$result = foreach ($group in $GroupName) {
    try {
        Get-ADGroupMember -Identity $group -Recursive -ErrorAction Stop | ForEach-Object {
            [PSCustomObject]@{
                GroupName         = $group
                Name              = $_.Name
                SamAccountName    = $_.SamAccountName
                ObjectClass       = $_.ObjectClass
                DistinguishedName = $_.DistinguishedName
            }
        }
    }
    catch {
        [PSCustomObject]@{
            GroupName         = $group
            Name              = $null
            SamAccountName    = $null
            ObjectClass       = "ERRO"
            DistinguishedName = $_.Exception.Message
        }
    }
}

$result | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
