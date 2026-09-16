<#
.SYNOPSIS
    Gera relatório de computadores do AD por faixa de inatividade.
#>
[CmdletBinding()]
param(
    [int[]]$Thresholds = @(30,60,90,120),
    [string]$SearchBase,
    [switch]$IncludeDisabled,
    [string]$OutputPath
)

Import-Module ActiveDirectory -ErrorAction Stop
$now = Get-Date
$sortedThresholds = $Thresholds | Sort-Object -Unique

$params = @{
    Filter = '*'
    Properties = @('Enabled','LastLogonDate','PasswordLastSet','OperatingSystem','DNSHostName')
}
if ($SearchBase) { $params.SearchBase = $SearchBase }

$result = Get-ADComputer @params | Where-Object { $IncludeDisabled -or $_.Enabled } | ForEach-Object {
    $inactiveDays = if ($_.LastLogonDate) { [int]($now - $_.LastLogonDate).TotalDays } else { $null }
    $bucket = if ($null -eq $inactiveDays) {
        'Nunca efetuou logon'
    } else {
        $matched = $sortedThresholds | Where-Object { $inactiveDays -ge $_ } | Select-Object -Last 1
        if ($matched) { "$matched+ dias" } else { "Menos de $($sortedThresholds[0]) dias" }
    }

    [PSCustomObject]@{
        Name            = $_.Name
        Enabled         = $_.Enabled
        DNSHostName     = $_.DNSHostName
        OperatingSystem = $_.OperatingSystem
        LastLogonDate   = $_.LastLogonDate
        InactiveDays    = $inactiveDays
        InactivityRange = $bucket
        PasswordLastSet = $_.PasswordLastSet
    }
}

$result = $result | Sort-Object @{Expression='InactiveDays';Descending=$true}, Name
$result

if ($OutputPath) {
    $result | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
}
