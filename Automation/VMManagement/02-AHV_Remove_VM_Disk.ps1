# Author :  bruno.sousa@{nutanix,gmail}.com
# Date of Creation : June, 2019
# @bsousapt on Twitter
# http://www.npx15.com
# 
# Acknowledgements 
# Kees Baggerman for ideas taken from the scripts published at http://blog.myvirtualvision.com/
# Google . Who can work without Google these days ?!
#
#
# Description  
# AHV Remove disks fromv m
# Script that removes *all* disks (except CDROM and disk scsi-0) from a  VM running on a Nutanix AHV Cluster
#
# V 0.1 -- Initial Release
#


# Load the Nutanix snap-in

Add-PSSnapin -Name NutanixCmdletsPSSnapin

    if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue))
    {
        write-host  "Nutanix CMDlets are not loaded, aborting the script"
        write-host "" 
        break
    }
    else
     {
        write-host "Nutanix CMDlets loaded. Moving on...."
        write-host ""
     }

#### Variables Definition -- Start 

# Cluster Connection Variables  

$Cluster_IP        = ""
$Cluster_Login     = "admin"
$Cluster_Password  = convertto-securestring "prism admin user password" -asplaintext -force

# Container where vdisks will be hosted at 
$ContainerName   = 'container-name'

# Name of the VM to add disks to
$VM_Name = "vm to work on "

#### Variables Definition -- End 


# Let's disconnect from any possible cluster to make sure we start fresh :)

Disconnect-NTNXCluster *

write-host  "Disconnecting from any previously connected cluster"
write-host "" 

# Now we can go ahead and  connect to the Nutanix cluster

write-host "Connecting to the Nutanix cluster at $Cluster_IP using `"$Cluster_Login`" as username"
write-host ""

$ClusterConnection = Connect-NutanixCluster -Server   $Cluster_IP `
                                            -UserName $Cluster_Login `
                                            -Password $Cluster_Password `
                                            -AcceptInvalidSSLCerts `
                                            -ForcedConnection

# Let's verify if connection to cluster was done with success 

If ( !$ClusterConnection.IsConnected )
{
    Throw "Error connecting to the Nutanix cluster"
}


write-host "Connected to $Cluster_IP" -ForegroundColor Green
write-host "" 

# Search for the VM Name and grab it's ID. ID is needed to use as argument when removing disk(s) from the vm 
$vminfo = Get-NTNXVM | Where-Object {$_.vmName -like $VM_Name}
$vmId = ($vminfo.vmid.split(":"))[2]

write-host "Working on container $ContainerName for VM $VM_Name with ID $vmID" 
write-host ""

$CurrentDisks = Get-NTNXVMDisk -Vmid $vmId -IncludeDiskSizes | Where-Object {$_.isCdrom -eq $false} | where-object {$_.id -gt "scsi-0"}

$CurrentDisks = $CurrentDisks | Sort-Object id
If(-not [string]::IsNullOrEmpty($CurrentDisks)) {
    #Remove Disk(s) 
    Foreach ($CurrentDisk in $CurrentDisks){
        write-host ""
        Write-Verbose "Removing disk: $($CurrentDisk.id) " -Verbose
    }
     }

