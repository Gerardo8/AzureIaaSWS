# Set values for existing resource group and storage account names
$rgName="[Your-resourcegroup-name]"
$locName="[Your-region-name]"
$saName="[Your-storage-account-name]"

# Set the existing virtual network and subnet index
$vnetName="[Your-virtual-network-name]"
$subnetIndex=0
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName


# Create the NIC

$nicName="LOB07-NIC"
$lbName="lab5-LB"
$bePoolIndex=0
$natRuleIndex=0
$lb=Get-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName
$nic=New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -Subnet $vnet.Subnets[$subnetIndex] -LoadBalancerBackendAddressPool $lb.BackendAddressPools[$bePoolIndex] -LoadBalancerInboundNatRule $lb.InboundNatRules[$natRuleIndex]


# Specify the name, size, and existing availability set
$vmName="LOB07"
$vmSize="Standard_A3"
$avName="[Your-availability-set-name]"
$avSet=Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avName
$vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id

# Add a 200 GB additional data disk
$diskSize=200
$diskLabel="APPStorage"
$diskName="21050529-DISK02"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
Add-AzureRmVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI -CreateOption empty

# Specify the image and local administrator account, and then add the NIC
$pubName="MicrosoftWindowsServer"
$offerName="WindowsServer"
$skuName="2012-R2-Datacenter"
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk name and create the VM
$diskName="OSDisk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm

