<#
.SYNOPSIS
    Testa conectividade e disponibilidade do WinRM em vários computadores.
.EXAMPLE
    .\Test-WinRMFleet.ps1 -ComputerName PC001,PC002
.EXAMPLE
    Get-Content .\computers.txt | .\Test-WinRMFleet.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName,

    [string]$OutputPath = ".\WinRMFleet.csv"
)

begin {
    $results = @()
}

process {
    foreach ($computer in $ComputerName) {
        Write-Host "Testando $computer..." -ForegroundColor Cyan

        $ping = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction SilentlyContinue

        $port445 = $false
        $port5985 = $false

        try {
            $port445 = Test-NetConnection -ComputerName $computer -Port 445 -InformationLevel Quiet -WarningAction SilentlyContinue
        } catch {}

        try {
            $port5985 = Test-NetConnection -ComputerName $computer -Port 5985 -InformationLevel Quiet -WarningAction SilentlyContinue
        } catch {}

        $winrm = $false
        if ($port5985) {
            try {
                Test-WSMan -ComputerName $computer -ErrorAction Stop | Out-Null
                $winrm = $true
            } catch {}
        }

        $results += [PSCustomObject]@{
            ComputerName = $computer
            Ping         = $ping
            Port445      = $port445
            Port5985     = $port5985
            WinRM        = $winrm
        }
    }
}

end {
    $results | Format-Table -AutoSize
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Relatório salvo em: $OutputPath" -ForegroundColor Green
}
