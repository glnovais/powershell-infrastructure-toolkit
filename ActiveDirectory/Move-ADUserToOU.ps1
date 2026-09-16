<#
.SYNOPSIS
    Move um usuário do Active Directory para outra OU.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)] [string]$Identity,
    [Parameter(Mandatory)] [string]$TargetOU
)

Import-Module ActiveDirectory -ErrorAction Stop
$user = Get-ADUser -Identity $Identity -Properties DistinguishedName -ErrorAction Stop
Get-ADOrganizationalUnit -Identity $TargetOU -ErrorAction Stop | Out-Null

if ($PSCmdlet.ShouldProcess($user.DistinguishedName, "Mover para $TargetOU")) {
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop
    Get-ADUser -Identity $user.SamAccountName | Select-Object Name, SamAccountName, DistinguishedName
}
