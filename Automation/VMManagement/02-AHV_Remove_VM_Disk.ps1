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
# AHV Add disk to VM 
# Script that adds disks to a VM running on a Nutanix AHV Cluster
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

# Number data disks to add
$Number_datadisks = 2

# Size of data disks to add in MB . I do X (where X is value in MB)  * 1024 to get MB into GB
$datadisks_size = 10 * 1024 

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

# Search for the VM Name and grab it's ID. ID is needed to use as argument when adding disk(s) to the VM
$vminfo = Get-NTNXVM | Where-Object {$_.vmName -like $VM_Name}
$vmId = ($vminfo.vmid.split(":"))[2]

write-host "Working on container $ContainerName for VM $VM_Name with ID $vmID" 
write-host ""

    #Setting up the create disk specification 
    $diskCreateSpec = New-NTNXObject -Name VmDiskSpecCreateDTO
    $diskcreatespec.containername = $ContainerName
    $diskcreatespec.sizeMb = $datadisks_size
    # Creating the Disk(s)
    $vmDisk =  New-NTNXObject –Name VMDiskDTO
    $vmDisk.vmDiskCreate = $diskCreateSpec

 # Adding the disk(s) to the VM

# This allows to iterate from 1 until the number of datadisks specified 
 1..$Number_datadisks | % { 

 Write-host "Creating Disk $_ with size" "$($datadisks_size/1024)" "GB on container $ContainerName for VM $VM_Name"
 Add-NTNXVMDisk -Vmid $vmId -Disks $vmDisk | Out-Null
 
 }

# Let's disconnect from any possible cluster to make sure we end the way we started

Disconnect-NTNXCluster *
