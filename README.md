# PowerShell Infrastructure Toolkit

Toolkit de automação para administração de infraestrutura Windows, Active Directory, Group Policy, WinRM, redes, inventário e suporte remoto.

O objetivo do projeto é reunir scripts reutilizáveis e parametrizados para tarefas comuns de operação e troubleshooting em ambientes Windows corporativos e laboratórios.

## Tecnologias

- PowerShell
- Active Directory
- Windows Server
- Group Policy
- WinRM / PowerShell Remoting
- TCP/IP e DNS
- CIM / WMI
- Windows Event Log

## Estrutura

```text
powershell-infrastructure-toolkit/
├── ActiveDirectory/
├── Diagnostics/
├── GPO/
├── Inventory/
├── Network/
├── Support/
└── WinRM/
```

## Active Directory

| Script | Finalidade |
|---|---|
| `Get-LastLogonReport.ps1` | Relatório de último logon de usuários |
| `Get-DisabledUsers.ps1` | Lista contas desabilitadas |
| `Get-EmptyGroups.ps1` | Localiza grupos sem membros |
| `Get-ComputerInventory.ps1` | Inventário de computadores cadastrados no AD |
| `Get-GroupMembersReport.ps1` | Exporta membros de grupos |
| `Unlock-ADUserSafe.ps1` | Desbloqueia usuário com confirmação |
| `Reset-ADUserPassword.ps1` | Redefine senha com entrada segura |
| `New-StandardADUser.ps1` | Cria usuário de forma parametrizada |
| `Move-ADUserToOU.ps1` | Move usuário entre OUs |
| `Move-ADComputerToOU.ps1` | Move computador entre OUs |
| `Get-InactiveADAccounts.ps1` | Classifica usuários por tempo de inatividade |
| `Get-InactiveADComputers.ps1` | Classifica computadores por tempo de inatividade |
| `Test-ComputerSecureChannelStatus.ps1` | Verifica o canal seguro com o domínio |
| `Repair-ComputerSecureChannel.ps1` | Repara o canal seguro com confirmação |
| `Repair-DomainTrustRemote.ps1` | Diagnostica e repara confiança remotamente via WinRM, com fallback e RDP opcional |

Procedimento detalhado: `ActiveDirectory/PROCEDIMENTO_REPARO_REMOTO_CONFIANCA_DOMINIO.md`.

## Group Policy

| Script | Finalidade |
|---|---|
| `Backup-AllGPOs.ps1` | Backup das GPOs |
| `Export-GPOReports.ps1` | Exporta relatórios HTML/XML |
| `Get-RemoteGPResult.ps1` | Consulta resultado de política remotamente |
| `Invoke-RemoteGPUpdate.ps1` | Executa atualização de política remotamente |

## WinRM

| Script | Finalidade |
|---|---|
| `Test-WinRMFleet.ps1` | Teste de WinRM em vários computadores |
| `Get-RemoteLoggedOnUser.ps1` | Consulta usuário remoto |
| `Test-RemoteManagementPorts.ps1` | Testa portas de gerenciamento |
| `Test-WinRMConfiguration.ps1` | Verifica serviço, listeners e firewall do WinRM |

## Rede

| Script | Finalidade |
|---|---|
| `Test-NetworkHosts.ps1` | Testa disponibilidade de hosts |
| `Resolve-HostInfo.ps1` | Resolve hostname, IPv4, IPv6 e aliases |
| `Test-TCPPortFleet.ps1` | Testa múltiplas portas TCP em múltiplos hosts |

## Suporte e inventário remoto

| Script | Finalidade |
|---|---|
| `Get-LoggedOnUserByHostname.ps1` | Consulta rápida do usuário logado por IP ou hostname |
| `Test-RDPStatus.ps1` | Verifica disponibilidade e configuração do RDP |
| `Get-RemoteDiskSpace.ps1` | Consulta espaço em disco |
| `Get-CriticalServices.ps1` | Verifica serviços críticos |
| `Get-RemoteEventLog.ps1` | Coleta eventos recentes |
| `Get-InstalledSoftware.ps1` | Lista softwares instalados sem Win32_Product |
| `Get-InstalledPrinters.ps1` | Lista impressoras instaladas |
| `Get-NetworkConfiguration.ps1` | Consulta IP, MAC, gateway e DNS |
| `Get-SystemUptime.ps1` | Consulta uptime do Windows |
| `Get-RemoteComputerSummary.ps1` | Resumo de hardware e sistema operacional |

## Diagnóstico

`Diagnostics/New-EndpointDiagnosticReport.ps1` gera um relatório HTML com conectividade, WinRM, sistema operacional, usuário, uptime, discos, rede e serviços essenciais.

## Requisitos

Dependendo do script, podem ser necessários:

```powershell
Import-Module ActiveDirectory
Import-Module GroupPolicy
```

Também podem ser necessários RSAT, permissões administrativas e PowerShell Remoting habilitado no destino.

## Exemplos

```powershell
# Testar WinRM
.\WinRM\Test-WinRMFleet.ps1 -ComputerName PC001,PC002

# Consultar contas inativas
.\ActiveDirectory\Get-InactiveADAccounts.ps1 -Thresholds 30,60,90,120

# Testar portas em massa
.\Network\Test-TCPPortFleet.ps1 -ComputerName server01,server02 -Port 80,443,3389

# Consultar usuário logado por IP ou hostname
.\Support\Get-LoggedOnUserByHostname.ps1

# Reparar remotamente a confiança de um computador com o domínio
.\ActiveDirectory\Repair-DomainTrustRemote.ps1 -ComputerName PC001 -IPAddress 10.0.0.50 -DomainName corp.local

# Criar relatório de diagnóstico
.\Diagnostics\New-EndpointDiagnosticReport.ps1 -ComputerName PC001
```

## Licença

MIT License.

## Autor

**Gustavo Lima Novais**  
Infraestrutura de Redes · Windows Server · Active Directory · Automação com PowerShell