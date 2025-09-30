# Connect to vCenter
$vcentersrv = "<vcenter server>"
Connect-VIserver -server $vcentersrv 

###############################################################

$esxiName = "<esxi hostname>"
$esxiUserName = "root"
$esxiNewPassword = ""

$esxi = Get-VMHost | Where-Object { $_.Name -eq $esxiName }

$esxcli = $esxi | Get-EsxCLI -V2

$rootUser = $esxcli.system.account.list.Invoke() | Where-Object { $_.UserID -eq $esxiUserName }

$userArg = $esxcli.system.account.set.CreateArgs()
$userArg.id = $rootUser.UserID
$userArg.password = $esxiNewPassword
$userArg.passwordconfirmation = $esxiNewPassword
$esxcli.system.account.set.Invoke($userArg)

Disconnect-VIServer * -Confirm:$false