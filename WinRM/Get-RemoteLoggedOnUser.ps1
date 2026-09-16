<#
.SYNOPSIS
    Consulta o usuário atualmente logado e o último usuário conhecido no Windows remoto.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ComputerName
)

try {
    $result = Invoke-Command -ComputerName $ComputerName -ErrorAction Stop -ScriptBlock {
        $currentUser = (Get-CimInstance Win32_ComputerSystem).UserName

        $lastUser = Get-ItemProperty `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" `
            -Name LastLoggedOnUser `
            -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            ComputerName        = $env:COMPUTERNAME
            CurrentLoggedOnUser = if ($currentUser) { $currentUser } else { "Nenhum usuário logado" }
            LastLoggedOnUser    = $lastUser.LastLoggedOnUser
        }
    }

    $result | Format-List
}
catch {
    Write-Error "Falha ao consultar $ComputerName. $($_.Exception.Message)"
}
