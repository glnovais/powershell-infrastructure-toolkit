<#
.SYNOPSIS
    Resolve informações básicas de DNS para um hostname ou IP.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Target
)

try {
    $entry = [System.Net.Dns]::GetHostEntry($Target)

    [PSCustomObject]@{
        Query    = $Target
        HostName = $entry.HostName
        IPv4     = ($entry.AddressList | Where-Object AddressFamily -eq InterNetwork) -join ', '
        IPv6     = ($entry.AddressList | Where-Object AddressFamily -eq InterNetworkV6) -join ', '
        Aliases  = $entry.Aliases -join ', '
    } | Format-List
}
catch {
    Write-Error "Não foi possível resolver '$Target'. $($_.Exception.Message)"
}
