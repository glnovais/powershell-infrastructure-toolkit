<#
.SYNOPSIS
    Verifica portas, serviço, listeners e regras de firewall relacionadas ao WinRM.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        $http = Test-NetConnection -ComputerName $computer -Port 5985 -InformationLevel Quiet -WarningAction SilentlyContinue
        $https = Test-NetConnection -ComputerName $computer -Port 5986 -InformationLevel Quiet -WarningAction SilentlyContinue
        $wsman = $false
        try {
            Test-WSMan -ComputerName $computer -ErrorAction Stop | Out-Null
            $wsman = $true
        } catch {}

        $details = $null
        if ($wsman) {
            try {
                $details = Invoke-Command -ComputerName $computer -ScriptBlock {
                    $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue
                    $listeners = @(Get-ChildItem WSMan:\localhost\Listener -ErrorAction SilentlyContinue)
                    $allowRules = @(Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | ForEach-Object {
                        $rule = $_
                        $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
                        if ($portFilter.LocalPort -in @('5985','5986')) {
                            $rule
                        }
                    })

                    [PSCustomObject]@{
                        ServiceStatus      = $service.Status
                        ServiceStartType   = $service.StartType
                        ListenerCount      = $listeners.Count
                        FirewallAllowRules = $allowRules.Count
                    }
                } -ErrorAction Stop
            } catch {}
        }

        [PSCustomObject]@{
            ComputerName       = $computer
            Port5985           = $http
            Port5986           = $https
            WSManResponding     = $wsman
            ServiceStatus       = $details.ServiceStatus
            ServiceStartType    = $details.ServiceStartType
            ListenerCount       = $details.ListenerCount
            FirewallAllowRules  = $details.FirewallAllowRules
        }
    }
}
