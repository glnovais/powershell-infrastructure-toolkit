<#
.SYNOPSIS
    Consulta IP, MAC, gateway e DNS de interfaces de rede ativas.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                $configs = Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.NetAdapter.Status -eq 'Up' }
                foreach ($cfg in $configs) {
                    [PSCustomObject]@{
                        ComputerName   = $env:COMPUTERNAME
                        InterfaceAlias = $cfg.InterfaceAlias
                        InterfaceIndex = $cfg.InterfaceIndex
                        MacAddress     = $cfg.NetAdapter.MacAddress
                        IPv4Address    = ($cfg.IPv4Address.IPAddress -join ', ')
                        Gateway        = ($cfg.IPv4DefaultGateway.NextHop -join ', ')
                        DNSServers     = ($cfg.DNSServer.ServerAddresses -join ', ')
                    }
                }
            } -ErrorAction Stop
        } catch {
            Write-Warning "Falha ao consultar rede em $computer: $($_.Exception.Message)"
        }
    }
}
