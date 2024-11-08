# List the latest supported hardware version and guest OS IDs
Connect-VIServer

$envBrowser = Get-View -Id (Get-View -Id (Get-VMHost).ExtensionData.Parent).EnvironmentBrowser
$vmxVersion = ($envBrowser.QueryConfigOptionDescriptor() | Where-Object {$_.DefaultConfigOption}).Key

Write-Host "Supported VMX hardware version: $vmxVersion" -ForegroundColor Green
Write-Host ""

Write-Host "Guest OS IDs" -ForegroundColor Green
$envBrowser.QueryConfigOption($vmxVersion, $null).GuestOSDescriptor | Select-Object -Property Id, FullName

Disconnect-VIServer * -Confirm:$false