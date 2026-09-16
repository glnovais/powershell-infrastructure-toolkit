<#
.SYNOPSIS
    Consulta o uptime de computadores Windows.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                $os = Get-CimInstance Win32_OperatingSystem
                $uptime = (Get-Date) - $os.LastBootUpTime
                [PSCustomObject]@{
                    ComputerName = $env:COMPUTERNAME
                    LastBoot     = $os.LastBootUpTime
                    Days         = $uptime.Days
                    Hours        = $uptime.Hours
                    Minutes      = $uptime.Minutes
                    TotalHours   = [math]::Round($uptime.TotalHours, 2)
                }
            } -ErrorAction Stop
        } catch {
            [PSCustomObject]@{ ComputerName=$computer; LastBoot=$null; Days=$null; Hours=$null; Minutes=$null; TotalHours=$null }
            Write-Warning "Falha ao consultar uptime em $computer: $($_.Exception.Message)"
        }
    }
}
