<#
.SYNOPSIS
    Diagnostica e repara remotamente a confiança de um computador Windows com o domínio.

.DESCRIPTION
    Usa WinRM pelo IP com uma conta administrativa local para evitar dependência do
    Kerberos quando o Secure Channel está quebrado. Tenta primeiro
    Test-ComputerSecureChannel -Repair e, se necessário, usa
    Reset-ComputerMachinePassword como fallback.

    O TrustedHosts é alterado somente durante a execução e restaurado no finally.
    Opcionalmente habilita e valida RDP.

.EXAMPLE
    .\Repair-DomainTrustRemote.ps1 `
        -ComputerName "PC001" `
        -IPAddress "10.0.0.50" `
        -DomainName "corp.local" `
        -LocalAdmin "Administrator" `
        -EnableRDP
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string]$IPAddress,

    [Parameter(Mandatory)]
    [string]$DomainName,

    [string]$LocalAdmin = "Administrator",

    [PSCredential]$LocalCredential,

    [PSCredential]$DomainCredential,

    [switch]$EnableRDP
)

$ErrorActionPreference = "Stop"

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " REPARO REMOTO DE CONFIANÇA NO DOMÍNIO" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Computador : $ComputerName"
Write-Host "IP         : $IPAddress"
Write-Host "Domínio    : $DomainName"

Write-Host "`n[1/7] Testando conectividade..." -ForegroundColor Cyan

$Ping = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet -ErrorAction SilentlyContinue
$WinRMPort = Test-NetConnection -ComputerName $IPAddress -Port 5985 -WarningAction SilentlyContinue

Write-Host "Ping       : $Ping"
Write-Host "WinRM 5985 : $($WinRMPort.TcpTestSucceeded)"

if (-not $WinRMPort.TcpTestSucceeded) {
    throw "A porta TCP 5985 não está acessível. Não é possível continuar via WinRM HTTP."
}

Write-Host "`n[2/7] Preparando TrustedHosts temporariamente..." -ForegroundColor Cyan

$TrustedHostsOriginal = [string](Get-Item WSMan:\localhost\Client\TrustedHosts).Value

try {
    if ($TrustedHostsOriginal -ne "*") {
        $TrustedList = @()

        if ($TrustedHostsOriginal) {
            $TrustedList += $TrustedHostsOriginal -split "," |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
        }

        $TrustedList += $IPAddress
        $TrustedList = $TrustedList | Select-Object -Unique

        Set-Item WSMan:\localhost\Client\TrustedHosts `
            -Value ($TrustedList -join ",") `
            -Force
    }

    Test-WSMan -ComputerName $IPAddress -ErrorAction Stop | Out-Null
    Write-Host "[OK] WinRM respondeu pelo IP." -ForegroundColor Green

    Write-Host "`n[3/7] Obtendo credenciais..." -ForegroundColor Cyan

    if (-not $LocalCredential) {
        $LocalCredential = Get-Credential `
            -UserName "$ComputerName\$LocalAdmin" `
            -Message "Informe a senha da conta administrativa local do computador."
    }

    if (-not $DomainCredential) {
        $DomainCredential = Get-Credential `
            -Message "Informe uma credencial administrativa do domínio $DomainName."
    }

    Write-Host "`n[4/7] Verificando Secure Channel..." -ForegroundColor Cyan

    $Before = Invoke-Command `
        -ComputerName $IPAddress `
        -Credential $LocalCredential `
        -Authentication Negotiate `
        -ScriptBlock {
            $ComputerSystem = Get-CimInstance Win32_ComputerSystem
            $Secure = Test-ComputerSecureChannel -ErrorAction SilentlyContinue

            [pscustomobject]@{
                ComputerName  = $env:COMPUTERNAME
                Domain        = $ComputerSystem.Domain
                PartOfDomain  = $ComputerSystem.PartOfDomain
                SecureChannel = [bool]$Secure
            }
        }

    $Before | Format-List

    if (-not $Before.PartOfDomain) {
        throw "O computador remoto não está associado a um domínio."
    }

    if (-not $Before.SecureChannel) {
        Write-Host "`n[5/7] Secure Channel quebrado. Reparando..." -ForegroundColor Yellow

        $RepairResult = Invoke-Command `
            -ComputerName $IPAddress `
            -Credential $LocalCredential `
            -Authentication Negotiate `
            -ScriptBlock {
                param($DomainCredential, $DomainName)

                $Result = Test-ComputerSecureChannel `
                    -Repair `
                    -Credential $DomainCredential `
                    -ErrorAction SilentlyContinue

                $Validation = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
                $Nltest = nltest "/sc_verify:$DomainName" 2>&1

                [pscustomobject]@{
                    RepairResult  = [bool]$Result
                    SecureChannel = [bool]$Validation
                    NLTest        = ($Nltest -join "`n")
                }
            } -ArgumentList $DomainCredential, $DomainName

        $RepairResult | Format-List

        if (-not $RepairResult.SecureChannel) {
            Write-Warning "O reparo padrão não restaurou o Secure Channel. Executando fallback."

            $Fallback = Invoke-Command `
                -ComputerName $IPAddress `
                -Credential $LocalCredential `
                -Authentication Negotiate `
                -ScriptBlock {
                    param($DomainCredential, $DomainName)

                    $DcLookup = nltest "/dsgetdc:$DomainName" 2>&1
                    $DC = $null

                    foreach ($Line in $DcLookup) {
                        if ($Line -match '\\\\([A-Za-z0-9._-]+)') {
                            $DC = $Matches[1]
                            break
                        }
                    }

                    if (-not $DC) {
                        throw "Não foi possível identificar automaticamente um controlador de domínio."
                    }

                    Reset-ComputerMachinePassword `
                        -Server $DC `
                        -Credential $DomainCredential `
                        -ErrorAction Stop

                    $Secure = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
                    $Nltest = nltest "/sc_verify:$DomainName" 2>&1

                    [pscustomobject]@{
                        DomainController = $DC
                        SecureChannel    = [bool]$Secure
                        NLTest           = ($Nltest -join "`n")
                    }
                } -ArgumentList $DomainCredential, $DomainName

            $Fallback | Format-List

            if (-not $Fallback.SecureChannel) {
                throw "Não foi possível restaurar o Secure Channel automaticamente."
            }
        }
    }
    else {
        Write-Host "[OK] O Secure Channel já está íntegro." -ForegroundColor Green
    }

    if ($EnableRDP) {
        Write-Host "`n[6/7] Habilitando/validando RDP..." -ForegroundColor Cyan

        Invoke-Command `
            -ComputerName $IPAddress `
            -Credential $LocalCredential `
            -Authentication Negotiate `
            -ScriptBlock {
                Set-ItemProperty `
                    "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                    -Name fDenyTSConnections `
                    -Value 0

                Set-ItemProperty `
                    "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                    -Name UserAuthentication `
                    -Value 1

                Enable-NetFirewallRule `
                    -Group "@FirewallAPI.dll,-28752" `
                    -ErrorAction SilentlyContinue

                Set-Service TermService -StartupType Manual

                if ((Get-Service TermService).Status -ne "Running") {
                    Start-Service TermService
                }
            }

        Start-Sleep -Seconds 2

        $RDP = Test-NetConnection `
            -ComputerName $IPAddress `
            -Port 3389 `
            -WarningAction SilentlyContinue

        Write-Host "RDP TCP/3389: $($RDP.TcpTestSucceeded)"
    }
    else {
        Write-Host "`n[6/7] RDP não solicitado." -ForegroundColor DarkGray
    }

    Write-Host "`n[7/7] Validação final..." -ForegroundColor Cyan

    $Final = Invoke-Command `
        -ComputerName $IPAddress `
        -Credential $LocalCredential `
        -Authentication Negotiate `
        -ScriptBlock {
            param($DomainName)

            $Secure = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
            $Nltest = nltest "/sc_verify:$DomainName" 2>&1

            [pscustomobject]@{
                ComputerName  = $env:COMPUTERNAME
                SecureChannel = [bool]$Secure
                NLTest        = ($Nltest -join "`n")
            }
        } -ArgumentList $DomainName

    $Final | Format-List

    if ($Final.SecureChannel) {
        Write-Host "`n[SUCESSO] Relação de confiança restaurada/validada." -ForegroundColor Green
    }
    else {
        throw "O Secure Channel ainda não está íntegro."
    }
}
finally {
    Write-Host "`nRestaurando TrustedHosts original..." -ForegroundColor DarkGray

    Set-Item WSMan:\localhost\Client\TrustedHosts `
        -Value $TrustedHostsOriginal `
        -Force `
        -ErrorAction SilentlyContinue
}
