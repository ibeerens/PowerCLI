# TPM Encryption Recovery Key Backup Alarm
# https://knowledge.broadcom.com/external/article?articleNumber=323401
# esxcli system settings encryption get
# esxcli system settings encryption recovery list

$vcenter_hostname = "<vcenterserver>"
$Cluster = "<clustername>" 

Connect-VIserver -Server $vcenter_hostname

# Get all hosts in the cluster
$VMHosts = Get-VMHost -Location (Get-Cluster $Cluster)

$Results = @{}

# Process each host
$CsvData = [System.Collections.ArrayList]@()
foreach ($VMHost in $VMHosts) {
    $hostname = $VMHost.Name
    Write-Host "Processing: $hostname" -ForegroundColor Cyan
    
    try {
        $result = (Get-EsxCli -VMHost $VMHost -V2).system.settings.encryption.recovery.list.Invoke()
        $Results[$hostname] = @{
            Status = if($result) {"Success"} else {"No Data"}
            Data = if($result) {$result} else {"No encryption settings"}
        }
        
        if($result -and $result.Count -gt 0) { 
            $result | Format-Table -AutoSize 
            # Extract detailed data for CSV
            foreach($item in $result) {
                [void]$CsvData.Add([PSCustomObject]@{
                    Hostname = $hostname
                    Key = if($item.Key) {$item.Key} else {"Unknown"}
                    RecoveryID = if($item.RecoveryID) {$item.RecoveryID} else {"Unknown"}
                })
            }
        } else {
            # Add entry for hosts with no data
            [void]$CsvData.Add([PSCustomObject]@{
                Hostname = $hostname
                Key = "No Data"
                RecoveryID = "No Data"
            })
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        $Results[$hostname] = @{Status = "Error"; Data = $errorMsg}
        Write-Warning "Error on $hostname : $errorMsg"
        # Add entry for hosts with errors
        [void]$CsvData.Add([PSCustomObject]@{
            Hostname = $hostname
            Key = "Error"
            RecoveryID = $errorMsg
        })
    }
}

# Summary report
Write-Host "`nSUMMARY:" -ForegroundColor Magenta
$Results.Keys | Sort-Object | ForEach-Object {
    $status = $Results[$_].Status
    $color = @{Success="Green"; "No Data"="Yellow"; Error="Red"}[$status]
    Write-Host "  $_ : $status" -ForegroundColor $color
}

# Export detailed CSV and cleanup
$CsvData | Export-Csv "ESXi_Encryption_Details_$(Get-Date -f 'yyyyMMdd_HHmmss').csv" -NoTypeInformation


# Get the Alarm
Get-AlarmDefinition -Name "TPM Encryption Recovery Key Backup Alarm"

# Disable the alarm
# Set-AlarmDefinition -AlarmDefinition $alarmDef -Enabled:$false

# Re-enable the alarm, which resets it to green
# Set-AlarmDefinition -AlarmDefinition $alarmDef -Enabled:$true

Disconnect-VIServer * -Confirm:$false