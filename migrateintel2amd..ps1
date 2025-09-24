<#
    Migrate VMs to a new cluster 
    All the VMs are powered off
    A snaphot of the VM is created
    The VM is migrated to te new cluster
Changelog:
    0.1 Initial creation

Author:     Ivo Beerens
Date:       24-09-2025
Example:    
            ./migrateintel2amd.ps1
#>

# Connect to the vCenter Server
$vcenter_hostname = "<vcenterserver>"
Connect-VIserver -Server $vcenter_hostname

# Variables
$targetcluster = "<clustername>"
$csvinput = '.\testvms.csv'
$logfile = '.\log.txt'
$mighost = '<migrationhost>'

# Read VM names from CSV
$vms = Import-Csv -Path $csvinput

function Write-Log {
    Param(
        $Message
    )
    function TS {Get-Date -Format 'dd:MM:yyyy_hh:mm:ss'}
    "[$(TS)]$Message" | Tee-Object -FilePath $logfile -Append | Write-Verbose
}

Write-Log 'Migrate VMs from the Intel cluster to the AMD cluster'
Write-Log " "

Read-Host "All the VMs in the $csvinput will be powered off and moved the the $targetcluster! Press any key to continue or CTRL+C to quit" | Out-Null

foreach ($vm in $vms) {
    $vmName = $vm.Name

    # Power Off the VM
    Write-Log "PowerOff all the VMs from the $csvinput file."
    $vmObject = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    
    if ($vmObject) {
        # Check the current power state from vSphere
        if ($vmObject.PowerState -eq 'PoweredOff') {
            Write-Log "VM $vmName is already powered off."
            Write-Host "VM $vmName is already powered off." -ForegroundColor Yellow
        } else {
            Write-Log "Shutting down VM $vmName."
            Write-Host "Shutting down VM $vmName." -ForegroundColor Green
            Stop-VM -VM $vmObject -Confirm:$false
            Start-Sleep -Seconds 10
        }
    } else {
        Write-Log "VM $vmName not found in vSphere inventory."
        Write-Host "VM $vmName not found in vSphere inventory." -ForegroundColor Red
    }
    
    # Create snapshot
    Write-Log "Snapshot VM $vmName." -Append
    Write-Host "Snapshot VM $vmName." -ForegroundColor Green
    New-Snapshot -VM $vmName -Name "Before Intel2AMD VM move." -Description "Before Intel2AMD VM move." -Memory:$false -Quiesce:$false

    # Move VM to new cluster
    Write-Log "Move VM $vmObject to $targetcluster Cluster."
    Write-Host "Move VM $vmObject to $targetcluster Cluster." -ForegroundColor Green
    $vmObject | Move-VM -Destination (Get-VMHost -name $mighost)
    Start-Sleep -Seconds 2

    # # Power on the VM
    # Write-Log "Start VM $vmName"
    # Write-Host "Start VM $vmName" -ForegroundColor Green
    # Start-VM -VM $vmName -WhatIf
}

Disconnect-VIServer * -Confirm:$false