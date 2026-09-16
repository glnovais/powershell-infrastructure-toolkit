<#
.SYNOPSIS
    Coleta eventos recentes de um log do Windows em computador remoto.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ComputerName,
    [ValidateSet('System','Application','Security')] [string]$LogName = 'System',
    [int]$Hours = 24,
    [int]$MaxEvents = 100,
    [string]$OutputPath
)

$startTime = (Get-Date).AddHours(-$Hours)

try {
    $events = Invoke-Command -ComputerName $ComputerName -ArgumentList $LogName,$startTime,$MaxEvents -ScriptBlock {
        param($Log,$Start,$Limit)
        Get-WinEvent -FilterHashtable @{ LogName=$Log; StartTime=$Start } -MaxEvents $Limit -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
    } -ErrorAction Stop

    $events
    if ($OutputPath) {
        $events | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Eventos salvos em: $OutputPath" -ForegroundColor Green
    }
} catch {
    Write-Error "Falha ao consultar eventos em $ComputerName. $($_.Exception.Message)"
}
