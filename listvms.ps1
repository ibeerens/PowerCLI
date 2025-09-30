$vcentersrv = "<vcenter server>"

# Import the VMware.PowerCLI module 
Get-Module -ListAvailable VMware.PowerCLI | Import-Module
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vCenter
Connect-VIserver -server $vcentersrv -user 'administrator@vsphere.local' 

#Gathering VM settings
Write-Host "Gathering VM statistics"
$Report = @()
Get-VM | Sort Name -Descending | % {
	$vm = Get-View $_.ID
    $esxHost = Get-View $vm.Runtime.Host
	$vms = "" | Select-Object VMName, Hostname, IPAddress, OS, Boottime, VMState, TotalCPU, CPUAffinity, CPUHotAdd, CPUShare, CPUlimit, OverallCpuUsage, CPUreservation, `
    TotalMemory, MemoryShare, MemoryUsage, MemoryHotAdd, MemoryLimit, MemoryReservation, Swapped, Ballooned, Compressed, TotalNics, ToolsStatus, ToolsVersion, HardwareVersion, `
    TimeSync, CBT, ConsolidationNeeded, vmxpath,  ESXihost
	$vms.VMName = $vm.Name
	$vms.Hostname = $vm.Guest.hostname
	$vms.IPAddress = $vm.guest.ipAddress
	$vms.OS = $vm.Config.GuestFullName
	$vms.Boottime = $vm.Runtime.BootTime
	$vms.VMState = $vm.summary.runtime.powerState
	$vms.TotalCPU = $vm.summary.config.numcpu
	$vms.CPUAffinity = $vm.Config.CpuAffinity
	$vms.CPUHotAdd = $vm.Config.CpuHotAddEnabled
	$vms.CPUShare = $vm.Config.CpuAllocation.Shares.Level
	$vms.TotalMemory = $vm.summary.config.memorysizemb
	$vms.MemoryHotAdd = $vm.Config.MemoryHotAddEnabled
	$vms.MemoryShare = $vm.Config.MemoryAllocation.Shares.Level
	$vms.TotalNics = $vm.summary.config.numEthernetCards
	$vms.OverallCpuUsage = $vm.summary.quickStats.OverallCpuUsage
	$vms.MemoryUsage = $vm.summary.quickStats.guestMemoryUsage
	$vms.ToolsStatus = $vm.guest.toolsstatus
	$vms.ToolsVersion = $vm.config.tools.toolsversion
	$vms.TimeSync = $vm.Config.Tools.SyncTimeWithHost
	$vms.HardwareVersion = $vm.config.Version
	$vms.MemoryLimit = $vm.resourceconfig.memoryallocation.limit
	$vms.MemoryReservation = $vm.resourceconfig.memoryallocation.reservation
	$vms.CPUreservation = $vm.resourceconfig.cpuallocation.reservation
	$vms.CPUlimit = $vm.resourceconfig.cpuallocation.limit
	$vms.CBT = $vm.Config.ChangeTrackingEnabled
	$vms.Swapped = $vm.Summary.QuickStats.SwappedMemory
	$vms.Ballooned = $vm.Summary.QuickStats.BalloonedMemory
	$vms.Compressed = $vm.Summary.QuickStats.CompressedMemory
	$vms.ConsolidationNeeded = $vm.runtime.consolidationNeeded
    $vms.vmxpath = $vm.Summary.Config.VmPathName
    $vms.ESXihost = $esxHost.Name
	$Report += $vms
}
$report | Out-GridView

# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "VM_Report_$timestamp.csv"
$Report | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Report exported to $csvPath"

Disconnect-VIServer * -Confirm:$false