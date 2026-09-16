<#
.SYNOPSIS
    Verifica o Secure Channel de computadores Windows com o domínio.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        $online = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $online) {
            [PSCustomObject]@{ ComputerName=$computer; Online=$false; SecureChannel=$null; Status='Offline ou inacessível' }
            continue
        }

        try {
            $secure = if ($computer -eq $env:COMPUTERNAME -or $computer -in @('localhost','.')) {
                Test-ComputerSecureChannel -ErrorAction Stop
            } else {
                Invoke-Command -ComputerName $computer -ScriptBlock { Test-ComputerSecureChannel -ErrorAction Stop } -ErrorAction Stop
            }

            [PSCustomObject]@{
                ComputerName  = $computer
                Online        = $true
                SecureChannel = [bool]$secure
                Status        = if ($secure) { 'OK' } else { 'Falha' }
            }
        } catch {
            [PSCustomObject]@{ ComputerName=$computer; Online=$true; SecureChannel=$null; Status=$_.Exception.Message }
        }
    }
}
