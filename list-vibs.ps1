$VCserver = ""

# Connect to the vCenter server 
Connect-VIServer -server $VCserver

$list = @()
$hosts = Get-VMHost

foreach ($vihost in $hosts) {
    $esxcli = Get-VMHost $vihost | Get-EsxCli
    $list += $esxcli.software.vib.list() | Where-Object {
        $_.Version -eq "231.0.153.0-1OEM.700.1.0.15843807" -or $_.Vendor -eq "HPE"
    } | Select-Object @{
        Name = "VMHost"; Expression = { $esxcli.VMHost }
    }, Name, Vendor, Version, CreationDate, InstallDate, AcceptanceLevel
}

$list | Sort-Object Name | Out-GridView

# Disconnect session vCenter 
Disconnect-VIserver -Confirm:$false

# End
