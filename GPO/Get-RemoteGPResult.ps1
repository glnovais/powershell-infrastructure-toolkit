<#
.SYNOPSIS
    Executa gpresult remotamente por PowerShell Remoting.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ComputerName,
    [ValidateSet('Computer','User')] [string]$Scope = 'Computer'
)

try {
    Invoke-Command -ComputerName $ComputerName -ArgumentList $Scope -ScriptBlock {
        param($RequestedScope)
        gpresult.exe /R /SCOPE $RequestedScope.ToUpperInvariant()
    } -ErrorAction Stop
} catch {
    Write-Error "Não foi possível obter o GPResult de $ComputerName. $($_.Exception.Message)"
}
