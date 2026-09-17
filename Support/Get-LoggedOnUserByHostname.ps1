<#
.SYNOPSIS
    Consulta o usuário atualmente logado em um computador remoto por IP ou hostname.
#>

$PC = Read-Host "Digite o IP ou hostname do computador"

Write-Host "`nConsultando $PC..." -ForegroundColor Cyan

if (-not (Test-Connection -ComputerName $PC -Count 1 -Quiet)) {
    Write-Host "Computador não respondeu ao ping." -ForegroundColor Red
    return
}

try {
    $Usuario = (Get-CimInstance Win32_ComputerSystem -ComputerName $PC -ErrorAction Stop).UserName

    Write-Host "`n==============================" -ForegroundColor DarkGray
    Write-Host "Computador : $PC"

    if ($Usuario) {
        Write-Host "Usuário     : $Usuario" -ForegroundColor Green
    }
    else {
        Write-Host "Usuário     : Nenhum usuário logado" -ForegroundColor Yellow
    }

    Write-Host "==============================" -ForegroundColor DarkGray
}
catch {
    Write-Host "`nCIM não respondeu. Tentando via QUSER..." -ForegroundColor Yellow

    try {
        quser /server:$PC
    }
    catch {
        Write-Host "Não foi possível consultar o computador." -ForegroundColor Red
    }
}
