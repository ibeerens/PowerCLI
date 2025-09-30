# Set-SSHState -EnableSSH $true
# Set-SSHState -EnableSSH $false

$vcentersrv = "<vcenter server>"

# # Import the VMware.PowerCLI module 
# Get-Module -ListAvailable VMware.PowerCLI | Import-Module
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# # Connect to vCenter
Connect-VIserver -server $vcentersrv -user 'administrator@vsphere.local' 

function Set-SSHOnAllHosts {
    param (
        [bool]$EnableSSH
    )

    $esxiHosts = Get-VMHost

    foreach ($esxi in $esxiHosts) {
        $sshService = Get-VMHostService -VMHost $esxi | Where-Object { $_.Key -eq "TSM-SSH" }

        if ($EnableSSH) {
            if (-not $sshService.Running) {
                Write-Host "Enabling SSH on host: $($esxi.Name)"
                Start-VMHostService -HostService $sshService -Confirm:$false
            } else {
                Write-Host "SSH already enabled on host: $($esxi.Name)"
            }
        } else {
            if ($sshService.Running) {
                Write-Host "Disabling SSH on host: $($esxi.Name)"
                Stop-VMHostService -HostService $sshService -Confirm:$false
            } else {
                Write-Host "SSH already disabled on host: $($esxi.Name)"
            }
        }
    }
}

#Set-SSHOnAllHosts -EnableSSH $true
Set-SSHOnAllHosts -EnableSSH $false

Disconnect-VIServer * -Confirm:$false