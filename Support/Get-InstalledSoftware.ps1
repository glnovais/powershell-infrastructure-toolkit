<#
.SYNOPSIS
    Lista softwares instalados consultando as chaves de Uninstall do Registro.
.DESCRIPTION
    Evita o uso de Win32_Product.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName
)

process {
    foreach ($computer in $ComputerName) {
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                $paths = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
                )

                Get-ItemProperty $paths -ErrorAction SilentlyContinue |
                    Where-Object DisplayName |
                    Select-Object @{N='ComputerName';E={$env:COMPUTERNAME}}, DisplayName, DisplayVersion, Publisher, InstallDate |
                    Sort-Object DisplayName -Unique
            } -ErrorAction Stop
        } catch {
            Write-Warning "Falha ao consultar softwares em $computer: $($_.Exception.Message)"
        }
    }
}
