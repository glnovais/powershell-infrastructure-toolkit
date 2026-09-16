<#
.SYNOPSIS
    Consulta espaço em discos locais de computadores remotos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName,
    [double]$WarningPercentFree = 15
)

process {
    foreach ($computer in $ComputerName) {
        try {
            Invoke-Command -ComputerName $computer -ArgumentList $WarningPercentFree -ScriptBlock {
                param($Warning)
                Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
                    $percentFree = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 }
                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        Drive        = $_.DeviceID
                        SizeGB       = [math]::Round($_.Size / 1GB, 2)
                        FreeGB       = [math]::Round($_.FreeSpace / 1GB, 2)
                        PercentFree  = $percentFree
                        Status       = if ($percentFree -lt $Warning) { 'Warning' } else { 'OK' }
                    }
                }
            } -ErrorAction Stop
        } catch {
            [PSCustomObject]@{ ComputerName=$computer; Drive=$null; SizeGB=$null; FreeGB=$null; PercentFree=$null; Status=$_.Exception.Message }
        }
    }
}
