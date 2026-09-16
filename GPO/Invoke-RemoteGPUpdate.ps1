<#
.SYNOPSIS
    Solicita atualização remota de Group Policy.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)] [string[]]$ComputerName,
    [ValidateSet('Computer','User')] [string]$Target = 'Computer',
    [switch]$Force
)

Import-Module GroupPolicy -ErrorAction Stop

foreach ($computer in $ComputerName) {
    if ($PSCmdlet.ShouldProcess($computer, "Atualizar GPO - Target: $Target")) {
        try {
            $params = @{
                Computer             = $computer
                Target               = $Target
                RandomDelayInMinutes = 0
                ErrorAction          = 'Stop'
            }
            if ($Force) { $params.Force = $true }

            Invoke-GPUpdate @params | Out-Null
            [PSCustomObject]@{ ComputerName=$computer; Target=$Target; Requested=$true; Error=$null }
        } catch {
            [PSCustomObject]@{ ComputerName=$computer; Target=$Target; Requested=$false; Error=$_.Exception.Message }
        }
    }
}
