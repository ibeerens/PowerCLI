<#
    Created by: Ivo Beerens
    Date: 09-03-2021
    Changes: v1.0 VMware Hosts Statistics
 #>

# Variables
$Date = $null
$Time = $null
$Date = Get-Date -DisplayHint Date -Format dd/MM/yyy
$Time = Get-Date -Format HH:mm:ss

 
$vcentersrv = "<vcenter server>"

# Import the VMware.PowerCLI module 
Get-Module -ListAvailable VMware.PowerCLI | Import-Module
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vCenter
Connect-VIserver -server $vcentersrv -user 'administrator@vsphere.local' 

# Connect to the VCSA
Connect-VIServer $VCserver

# Clear screen
Clear-Host

# Get vCenter Server version
$VCversion = get-view serviceinstance
$vcenter_version = $vcversion.content.about.FullName
Write-Host "vCenter Server: $VCserver" -ForegroundColor Green
Write-Host $vcenter_version -ForegroundColor Green

# VMhost info
Write-Output "", "Information about VMhosts"
$Hardwares = Get-VMHostHardware
$myCol = @()
ForEach ($Hardware in $Hardwares) {
    $row = "" | Select-Object VMhost, Boottime, vCenter, 'Cluster Name', Date, Time, 
    Manufacturer, Model, BiosVersion, BiosDate, SerialNumber, AssetTag,
    CPUCount, CpuModel, CpuCoreCountTotal, Hypertreading, MhzPerCpu,
    Memory, MemorySlotCount, MemoryModules,
    Nics, Version, Build, LatestPatchInstalled
    $row.VMHost = $Hardware.VMHost
    $row.BootTime = $hardware.VMHost.ExtensionData.Summary.Runtime.BootTime
    $row.vCenter = $Global:defaultviserver.Name
    $row.'Cluster name' = $Hardware.VMHost | Get-Cluster | Select-Object -ExcludeProperty Name
    $row.Date = $date
    $row.Time = $Time
    $row.Manufacturer = $Hardware.Manufacturer
    $row.Model = $Hardware.Model
    $row.BiosVersion = $Hardware.BiosVersion
    $row.BiosDate = (($Hardware.VMHost.ExtensionData.Hardware.BiosInfo.ReleaseDate -split " ")[0])
    $row.SerialNumber = $Hardware.SerialNumber
    $row.AssetTag = $Hardware.AssetTag
    $row.CPUCount = $Hardware.CpuCount
    $row.CpuModel = $Hardware.CpuModel
    $row.CpuCoreCountTotal = $Hardware.CpuCoreCountTotal
    $row.Hypertreading = $Hardware.VMHost.HyperthreadingActive
    $row.MhzPerCpu = $Hardware.MhzPerCpu
    $row.Memory = [math]::Round($Hardware.VMHost.MemoryTotalGB,0)
    $row.MemoryModules = $Hardware.MemoryModules
    $row.MemorySlotCount = $Hardware.MemorySlotCount
    $row.Nics = $hardware.NicCount
    $row.Version = $Hardware.VMHost.ExtensionData.config.Product.Version
    $row.Build = $Hardware.VMhost.ExtensionData.Config.Product.Build
    $esxcli2 = Get-EsxCli -VMHost $Hardware.VMHost -V2
    $vmhostPatch = $esxcli2.software.vib.list.Invoke() | Where-Object {$_.ID -match $Hardware.VMhost.ExtensionData.Config.Product.Build} | Select-Object -First 1
    $row.LatestPatchInstalled = $vmhostPatch.InstallDate    
    $mycol += $row
}

Write-Output $myCol 
$myCol | Out-GridView

Disconnect-VIServer * -Confirm:$false