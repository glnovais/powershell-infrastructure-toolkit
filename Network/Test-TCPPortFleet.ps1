<#
.SYNOPSIS
    Testa múltiplas portas TCP em múltiplos hosts.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string[]]$ComputerName,
    [Parameter(Mandatory)] [ValidateRange(1,65535)] [int[]]$Port,
    [string]$OutputPath
)

$result = foreach ($computer in $ComputerName) {
    $ping = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction SilentlyContinue
    foreach ($p in $Port) {
        $open = Test-NetConnection -ComputerName $computer -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue
        [PSCustomObject]@{
            ComputerName = $computer
            Ping         = $ping
            Port         = $p
            Open         = $open
            CheckedAt    = Get-Date
        }
    }
}

$result
if ($OutputPath) {
    $result | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Resultado salvo em: $OutputPath" -ForegroundColor Green
}
