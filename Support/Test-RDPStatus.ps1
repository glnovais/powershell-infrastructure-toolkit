<#
.SYNOPSIS
    Verifica porta, serviço e configuração básica do Remote Desktop.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        $portOpen = Test-NetConnection -ComputerName $computer -Port 3389 -InformationLevel Quiet -WarningAction SilentlyContinue
        $enabled = $null
        $serviceStatus = $null

        try {
            $remote = Invoke-Command -ComputerName $computer -ScriptBlock {
                $deny = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction Stop).fDenyTSConnections
                $service = Get-Service TermService -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    RDPEnabled = ($deny -eq 0)
                    ServiceStatus = $service.Status
                }
            } -ErrorAction Stop
            $enabled = $remote.RDPEnabled
            $serviceStatus = $remote.ServiceStatus
        } catch {}

        [PSCustomObject]@{
            ComputerName  = $computer
            Port3389Open  = $portOpen
            RDPEnabled    = $enabled
            ServiceStatus = $serviceStatus
        }
    }
}
