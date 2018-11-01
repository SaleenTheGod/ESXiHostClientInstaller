#Download and Install ESXi Host Client on all hosts in vCenter
#This sample script will download the latest ESXi Host Client from the VMware Labs site and install on all hosts in vCenter, just change the vCenter name and credentials and make sure you have internet access.

$vsphereFQDN = "IP GOES HERE"
$vsphereUsername = "USERNAME GOES HERE"
$vspherePassword = "PASSWORD GOES HERE"

Connect-viserver $vsphereFQDN -user $vsphereUsername -Password $vspherePassword

Write-Host "Downloading latest Host Client VIB" -ForegroundColor Green
$source = "http://download3.vmware.com/software/vmw-tools/esxui/esxui_signed.vib"
$Vib = "$ENV:Temp" + "\esxui_signed.vib"
 
Invoke-WebRequest $source -OutFile $Vib

$Vibname = $vib.split("\")[-1]
Get-VMHost | Foreach {
    Write-host "Installing ESXUI on $($_)" -ForegroundColor Green
    $datastore = $_ | Get-Datastore | Where {-Not $_.ExtensionData.Summary.MultipleHostAccess -and $_.Extensiondata.Info.vmfs} | Sort FreespaceGB -Descending | Select -first 1
    If (-not $Datastore) {
        Write-Host "Local Datastore not found trying any with space" -ForegroundColor Green
        $datastore = $_ | Get-Datastore | Sort FreespaceGB -Descending | Select -first 1
    }
    $remoteLocation = "/vmfs/volumes/" + $datastore + "/" + $Vibname
    $Psdrive = New-PSDrive -name "VIBDS" -Root \ -PSProvider VimDatastore -Datastore $datastore
    Write-Host "..Copying file to $datastore" -ForegroundColor Green
    $CopyVIB = Copy-Datastoreitem $VIB -Destination VIBDS:
    Write-host "..Installing VIB on $($_)" -ForegroundColor Green
    $esxcli = Get-EsxCli -VMHost $_
    $esxcli.software.vib.install($null,$false,$true,$false,$false,$true,$null,$null,$remotelocation)
    Write-Host "Host Client Installed, removing install file from $datastore" -ForegroundColor Green
    Get-childitem "$($psdrive.Name):\esxui_signed.vib" | Remove-Item
    Remove-PSDrive -name VIBDS -Confirm:$false 
} 
