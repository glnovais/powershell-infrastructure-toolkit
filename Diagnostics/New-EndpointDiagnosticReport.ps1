<#
.SYNOPSIS
    Gera um relatório HTML de diagnóstico de um endpoint Windows.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ComputerName,
    [string]$OutputPath
)

if (-not $OutputPath) {
    $safeName = $ComputerName -replace '[^a-zA-Z0-9._-]','_'
    $OutputPath = Join-Path (Get-Location) "Diagnostic-$safeName-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
}

$ping = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue
$port445 = Test-NetConnection -ComputerName $ComputerName -Port 445 -InformationLevel Quiet -WarningAction SilentlyContinue
$port3389 = Test-NetConnection -ComputerName $ComputerName -Port 3389 -InformationLevel Quiet -WarningAction SilentlyContinue
$port5985 = Test-NetConnection -ComputerName $ComputerName -Port 5985 -InformationLevel Quiet -WarningAction SilentlyContinue

$summary = [PSCustomObject]@{
    ComputerName = $ComputerName
    Ping         = $ping
    SMB445       = $port445
    RDP3389      = $port3389
    WinRM5985    = $port5985
    CheckedAt    = Get-Date
}

$system = @()
$disks = @()
$network = @()
$services = @()
$errorMessage = $null

if ($port5985) {
    try {
        $remote = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $os = Get-CimInstance Win32_OperatingSystem
            $cs = Get-CimInstance Win32_ComputerSystem
            $uptime = (Get-Date) - $os.LastBootUpTime

            $systemInfo = [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                LoggedOnUser = $cs.UserName
                Manufacturer = $cs.Manufacturer
                Model        = $cs.Model
                RAMGB        = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                OS           = $os.Caption
                OSVersion    = $os.Version
                LastBoot     = $os.LastBootUpTime
                UptimeHours  = [math]::Round($uptime.TotalHours, 2)
            }

            $diskInfo = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
                [PSCustomObject]@{
                    Drive       = $_.DeviceID
                    SizeGB      = [math]::Round($_.Size / 1GB, 2)
                    FreeGB      = [math]::Round($_.FreeSpace / 1GB, 2)
                    PercentFree = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 }
                }
            }

            $networkInfo = Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.NetAdapter.Status -eq 'Up' } | ForEach-Object {
                [PSCustomObject]@{
                    Interface = $_.InterfaceAlias
                    MAC       = $_.NetAdapter.MacAddress
                    IPv4      = ($_.IPv4Address.IPAddress -join ', ')
                    Gateway   = ($_.IPv4DefaultGateway.NextHop -join ', ')
                    DNS       = ($_.DNSServer.ServerAddresses -join ', ')
                }
            }

            $serviceInfo = foreach ($name in @('WinRM','Dnscache','LanmanWorkstation','EventLog')) {
                $s = Get-Service $name -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Service   = $name
                    Status    = if ($s) { $s.Status } else { 'NotFound' }
                    StartType = if ($s) { $s.StartType } else { $null }
                }
            }

            [PSCustomObject]@{
                System   = $systemInfo
                Disks    = @($diskInfo)
                Network  = @($networkInfo)
                Services = @($serviceInfo)
            }
        } -ErrorAction Stop

        $system = @($remote.System)
        $disks = @($remote.Disks)
        $network = @($remote.Network)
        $services = @($remote.Services)
    } catch {
        $errorMessage = $_.Exception.Message
    }
} else {
    $errorMessage = 'WinRM não respondeu na porta 5985; informações remotas detalhadas não foram coletadas.'
}

$style = @'
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:32px;background:#f5f7fa;color:#1f2937}
h1{margin-bottom:4px} h2{margin-top:28px}
table{border-collapse:collapse;width:100%;background:white;margin:10px 0 20px}
th,td{border:1px solid #d1d5db;padding:8px;text-align:left}
th{background:#e5e7eb}.note{padding:12px;background:#fff7ed;border-left:4px solid #f59e0b}
</style>
'@

$body = @()
$body += '<h1>Endpoint Diagnostic Report</h1>'
$body += "<p>Host: <strong>$ComputerName</strong></p>"
$body += '<h2>Connectivity</h2>'
$body += ($summary | ConvertTo-Html -Fragment)

if ($errorMessage) {
    $body += "<div class='note'>$([System.Net.WebUtility]::HtmlEncode($errorMessage))</div>"
}
if ($system.Count) {
    $body += '<h2>System</h2>' + ($system | ConvertTo-Html -Fragment)
}
if ($disks.Count) {
    $body += '<h2>Disks</h2>' + ($disks | ConvertTo-Html -Fragment)
}
if ($network.Count) {
    $body += '<h2>Network</h2>' + ($network | ConvertTo-Html -Fragment)
}
if ($services.Count) {
    $body += '<h2>Services</h2>' + ($services | ConvertTo-Html -Fragment)
}

ConvertTo-Html -Title "Diagnostic - $ComputerName" -Head $style -Body ($body -join "`n") |
    Set-Content -Path $OutputPath -Encoding UTF8

Write-Host "Relatório criado: $OutputPath" -ForegroundColor Green
