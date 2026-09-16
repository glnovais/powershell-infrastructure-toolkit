<#
.SYNOPSIS
    Consulta o estado de serviços importantes em computadores remotos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName,
    [string[]]$ServiceName = @('WinRM','Dnscache','LanmanWorkstation','EventLog')
)

process {
    foreach ($computer in $ComputerName) {
        try {
            Invoke-Command -ComputerName $computer -ArgumentList (,$ServiceName) -ScriptBlock {
                param($Names)
                foreach ($name in $Names) {
                    $service = Get-Service -Name $name -ErrorAction SilentlyContinue
                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        ServiceName  = $name
                        DisplayName  = $service.DisplayName
                        Status       = if ($service) { $service.Status } else { 'NotFound' }
                        StartType    = if ($service) { $service.StartType } else { $null }
                    }
                }
            } -ErrorAction Stop
        } catch {
            [PSCustomObject]@{ ComputerName=$computer; ServiceName=$null; DisplayName=$null; Status='Unavailable'; StartType=$_.Exception.Message }
        }
    }
}
