<#
.SYNOPSIS
    Coleta um resumo do computador remoto via PowerShell Remoting.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ComputerName
)

Invoke-Command -ComputerName $ComputerName -ErrorAction Stop -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem

    $ipv4 = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notmatch '^127\.' -and
            $_.InterfaceAlias -notmatch 'Loopback'
        } |
        Select-Object -ExpandProperty IPAddress

    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        UserName     = $cs.UserName
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        RAM_GB       = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        OS           = $os.Caption
        OSVersion    = $os.Version
        LastBoot     = $os.LastBootUpTime
        IPv4         = $ipv4 -join ', '
    }
} | Format-List
