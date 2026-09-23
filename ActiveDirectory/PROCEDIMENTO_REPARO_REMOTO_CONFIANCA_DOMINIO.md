# Procedimento — Reparo Remoto de Confiança no Domínio

## Objetivo

Restaurar remotamente a relação de confiança de um computador Windows com o domínio sem retirar e recolocar a máquina no domínio como primeira tentativa.

O fluxo usa WinRM pelo IP com uma conta administrativa local, evitando depender do Kerberos enquanto o Secure Channel estiver quebrado.

## Pré-requisitos

- WinRM acessível no destino;
- conta administrativa local da estação;
- credencial com permissão para reparar a confiança no domínio;
- PowerShell executado como administrador na estação de suporte.

## Fluxo recomendado

1. Testar conectividade, TCP 5985 e `Test-WSMan`.
2. Salvar o `TrustedHosts` atual e adicionar temporariamente somente o IP do destino.
3. Conectar por IP usando a conta administrativa local e `-Authentication Negotiate`.
4. Validar com:

```powershell
Test-ComputerSecureChannel -Verbose
nltest /sc_verify:corp.local
```

5. Se a confiança estiver quebrada, executar:

```powershell
Test-ComputerSecureChannel -Repair -Credential $DomainCredential -Verbose
```

6. Validar novamente com `Test-ComputerSecureChannel` e `nltest`.
7. Se o reparo falhar, descobrir um DC real:

```powershell
nltest /dsgetdc:corp.local
```

8. Usar como fallback:

```powershell
Reset-ComputerMachinePassword -Server <DC_REAL> -Credential $DomainCredential
```

9. Validar novamente.
10. Se necessário, habilitar RDP e testar TCP 3389.
11. Restaurar o valor original de `TrustedHosts` no final.

## Script automatizado

Use `Repair-DomainTrustRemote.ps1`:

```powershell
.\Repair-DomainTrustRemote.ps1 `
    -ComputerName "PC001" `
    -IPAddress "10.0.0.50" `
    -DomainName "corp.local" `
    -LocalAdmin "Administrator"
```

Para também habilitar e validar RDP:

```powershell
.\Repair-DomainTrustRemote.ps1 `
    -ComputerName "PC001" `
    -IPAddress "10.0.0.50" `
    -DomainName "corp.local" `
    -LocalAdmin "Administrator" `
    -EnableRDP
```

As senhas são solicitadas com `Get-Credential` e não ficam gravadas no script.

## Resultado esperado

O Secure Channel deve retornar `True` e o `nltest` deve indicar sucesso na comunicação segura com o domínio.

## Importante

Não retire e recoloque o computador no domínio como primeira ação. Antes disso, tente:

- `Test-ComputerSecureChannel -Repair`;
- `Reset-ComputerMachinePassword`;
- validação de DNS e comunicação com os controladores de domínio.

Também evite configurar `TrustedHosts` como `*`. O script adiciona apenas o IP necessário e restaura a configuração anterior no `finally`.
