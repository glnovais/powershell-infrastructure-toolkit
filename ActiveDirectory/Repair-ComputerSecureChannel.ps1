<#
.SYNOPSIS
    Tenta reparar o Secure Channel de um computador Windows com o domínio.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$ComputerName,
    [PSCredential]$Credential
)

if (-not $Credential) {
    $Credential = Get-Credential -Message 'Informe uma credencial com permissão para reparar o vínculo com o domínio'
}

if ($PSCmdlet.ShouldProcess($ComputerName, 'Reparar Secure Channel')) {
    try {
        $result = if ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -in @('localhost','.')) {
            Test-ComputerSecureChannel -Repair -Credential $Credential -ErrorAction Stop
        } else {
            Invoke-Command -ComputerName $ComputerName -ArgumentList $Credential -ScriptBlock {
                param($DomainCredential)
                Test-ComputerSecureChannel -Repair -Credential $DomainCredential -ErrorAction Stop
            } -ErrorAction Stop
        }

        [PSCustomObject]@{
            ComputerName = $ComputerName
            Repaired     = [bool]$result
        }
    } catch {
        Write-Error "Falha ao reparar o Secure Channel de $ComputerName. $($_.Exception.Message)"
    }
}
