<#
.SYNOPSIS
    Redefine a senha de um usuário do Active Directory utilizando SecureString.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [SecureString]$NewPassword,

    [switch]$ChangePasswordAtLogon,

    [switch]$UnlockAfterReset
)

Import-Module ActiveDirectory -ErrorAction Stop
$user = Get-ADUser -Identity $Identity -Properties LockedOut -ErrorAction Stop

if (-not $NewPassword) {
    $NewPassword = Read-Host 'Digite a nova senha' -AsSecureString
}

if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Redefinir senha')) {
    Set-ADAccountPassword -Identity $user -Reset -NewPassword $NewPassword -ErrorAction Stop
    Set-ADUser -Identity $user -ChangePasswordAtLogon $ChangePasswordAtLogon.IsPresent -ErrorAction Stop

    if ($UnlockAfterReset -and $user.LockedOut) {
        Unlock-ADAccount -Identity $user -ErrorAction Stop
    }

    Write-Host "Senha redefinida para: $($user.SamAccountName)" -ForegroundColor Green
}
