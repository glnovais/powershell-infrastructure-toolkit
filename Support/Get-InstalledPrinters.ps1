<#
.SYNOPSIS
    Lista impressoras instaladas em computadores remotos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                Get-Printer -ErrorAction Stop | Select-Object @{N='ComputerName';E={$env:COMPUTERNAME}}, Name, DriverName, PortName, Type, Shared, Published
            } -ErrorAction Stop
        } catch {
            Write-Warning "Falha ao consultar impressoras em $computer: $($_.Exception.Message)"
        }
    }
}
