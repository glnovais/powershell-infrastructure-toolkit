<#
.SYNOPSIS
    Desbloqueia uma conta de usuário do Active Directory com confirmação.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Identity
)

Import-Module ActiveDirectory -ErrorAction Stop
$user = Get-ADUser -Identity $Identity -Properties LockedOut -ErrorAction Stop

if (-not $user.LockedOut) {
    Write-Host "A conta '$($user.SamAccountName)' não está bloqueada." -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Desbloquear conta do Active Directory')) {
    Unlock-ADAccount -Identity $user -ErrorAction Stop
    Write-Host "Conta desbloqueada: $($user.SamAccountName)" -ForegroundColor Green
}
