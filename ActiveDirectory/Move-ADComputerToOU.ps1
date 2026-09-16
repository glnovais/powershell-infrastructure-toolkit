<#
.SYNOPSIS
    Move um computador do Active Directory para outra OU.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)] [string]$Identity,
    [Parameter(Mandatory)] [string]$TargetOU
)

Import-Module ActiveDirectory -ErrorAction Stop
$computer = Get-ADComputer -Identity $Identity -Properties DistinguishedName -ErrorAction Stop
Get-ADOrganizationalUnit -Identity $TargetOU -ErrorAction Stop | Out-Null

if ($PSCmdlet.ShouldProcess($computer.DistinguishedName, "Mover para $TargetOU")) {
    Move-ADObject -Identity $computer.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop
    Get-ADComputer -Identity $computer.SamAccountName | Select-Object Name, Enabled, DistinguishedName
}
