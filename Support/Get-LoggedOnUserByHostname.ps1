<#
.SYNOPSIS
    Consulta rapidamente o usuário de um computador pelo hostname.
#>

$ComputerName = Read-Host "Digite o hostname do computador"

Write-Host "`nConsultando $ComputerName..." -ForegroundColor Cyan

try {
    Invoke-Command -ComputerName $ComputerName -ErrorAction Stop -ScriptBlock {
        $currentUser = (Get-CimInstance Win32_ComputerSystem).UserName

        $lastUser = Get-ItemProperty `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" `
            -Name LastLoggedOnUser `
            -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Hostname            = $env:COMPUTERNAME
            UsuarioLogadoAgora  = if ($currentUser) { $currentUser } else { "Nenhum usuário logado" }
            UltimoUsuarioLogado = $lastUser.LastLoggedOnUser
        }
    } | Format-List
}
catch {
    Write-Host "Erro ao consultar $ComputerName" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
}
