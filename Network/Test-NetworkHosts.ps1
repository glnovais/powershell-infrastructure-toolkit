<#
.SYNOPSIS
    Testa disponibilidade de hosts ou endereços IP.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$Target,

    [string]$OutputPath = ".\NetworkHosts.csv"
)

begin {
    $results = @()
}

process {
    foreach ($item in $Target) {
        $online = Test-Connection -ComputerName $item -Count 1 -Quiet -ErrorAction SilentlyContinue

        $resolvedName = $null
        try {
            $resolvedName = ([System.Net.Dns]::GetHostEntry($item)).HostName
        } catch {}

        $results += [PSCustomObject]@{
            Target       = $item
            Online       = $online
            ResolvedName = $resolvedName
            CheckedAt    = Get-Date
        }
    }
}

end {
    $results | Format-Table -AutoSize
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
}
