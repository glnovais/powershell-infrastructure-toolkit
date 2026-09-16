<#
.SYNOPSIS
    Testa portas comuns usadas no gerenciamento remoto de computadores Windows.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [int[]]$Ports = @(135, 139, 445, 3389, 5985, 5986)
)

foreach ($port in $Ports) {
    $open = Test-NetConnection `
        -ComputerName $ComputerName `
        -Port $port `
        -InformationLevel Quiet `
        -WarningAction SilentlyContinue

    [PSCustomObject]@{
        ComputerName = $ComputerName
        Port         = $port
        Open         = $open
    }
}
