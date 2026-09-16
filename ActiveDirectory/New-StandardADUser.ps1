<#
.SYNOPSIS
    Cria um usuário do Active Directory de forma parametrizada.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)] [string]$GivenName,
    [Parameter(Mandatory)] [string]$Surname,
    [Parameter(Mandatory)] [string]$SamAccountName,
    [Parameter(Mandatory)] [string]$UserPrincipalName,
    [Parameter(Mandatory)] [string]$Path,
    [string]$DisplayName,
    [string]$Description,
    [SecureString]$AccountPassword,
    [switch]$Enabled,
    [switch]$ChangePasswordAtLogon
)

Import-Module ActiveDirectory -ErrorAction Stop

if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue) {
    throw "Já existe uma conta com SamAccountName '$SamAccountName'."
}

if (-not $DisplayName) {
    $DisplayName = "$GivenName $Surname"
}

if (-not $AccountPassword) {
    $AccountPassword = Read-Host 'Digite a senha inicial' -AsSecureString
}

$params = @{
    Name                  = $DisplayName
    GivenName             = $GivenName
    Surname               = $Surname
    DisplayName           = $DisplayName
    SamAccountName        = $SamAccountName
    UserPrincipalName     = $UserPrincipalName
    Path                  = $Path
    AccountPassword       = $AccountPassword
    Enabled               = $Enabled.IsPresent
    ChangePasswordAtLogon = $ChangePasswordAtLogon.IsPresent
}

if ($Description) {
    $params.Description = $Description
}

if ($PSCmdlet.ShouldProcess($SamAccountName, "Criar usuário em '$Path'")) {
    New-ADUser @params -ErrorAction Stop
    Get-ADUser -Identity $SamAccountName | Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName
}
