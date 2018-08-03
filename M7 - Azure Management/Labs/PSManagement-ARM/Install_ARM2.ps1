<#
$subscr="[Your-subscription-Name]"
$rgName = "[Your-resourcegroup-name]"
$locName = "[Region]"
$saName = "[Your-storage-account-name]"
$saType="Standard_LRS"
$domName = "[Your-domain-name]"
$avName = "[Your-availability-set-name]"
$vnetName = "[Your-virtual-network-name]"
$publicipname = "[Your-publicIP-address-name]"
$lbName = "[Your-load-balancer-name]"
$nicName="LOB07-NIC"
$vmName="LOB07"
$vmSize="Standard_A3"
$currentDirectory = "[Local-directory-where-scripts-are-located]"
$contentInstallPath = "[Location where you xWebAdministration source folder exists]"
$configurationScript = Join-Path $currentDirectory 'SimpleWebServerConfiguration.ps1'
$configurationName = "InstallWebServer"
#>

$subscr="Azure Pass"
$rgName = "lwLab5"
$locName = "eastus"
$saName = "lwguchilab"
$saType="Standard_LRS"
$domName = "lwguchi"
$avName = "lwavailset"
$vnetName = "vnetLab5"
$publicipname = "lwlab5pubIP"
$lbName = "lbset"
$nicName="lwnic05"
$vmName="Lab05"
$vmSize="Standard_A3"
$currentDirectory = "C:\Workshops\Premier Shared IP\AzureIaaS\M5-Management\Labs\DesiredStateConfig\ScriptsComplete"
$contentInstallPath = "C:\Program Files\WindowsPowerShell\Modules\xWebAdministration\1.11.0.0"
$configurationScript = Join-Path $currentDirectory 'SimpleWebServerConfiguration.ps1'
$configurationName = "InstallWebServer"
$dscExtensionVersion = "2.14" #you may need to change this depending on which version of DSC is installed
$configurationArchive = [IO.Path]::GetFileName($configurationScript) + ".zip"
$configurationDataPath = Join-Path $currentDirectory "ConfigurationData.psd1"

# This is the location, on the new VM, where the Bakery web site code will be pulled from
$websiteSourceLocation = "C:\Program Files\WindowsPowerShell\Modules\xWebAdministration\BakeryWebsite"



Login-AzureRmAccount

Get-AzureRmSubscription | Sort SubscriptionName | Select SubscriptionName

Get-AzureRmSubscription –SubscriptionName $subscr | Select-AzureRmSubscription
New-AzureRmResourceGroup -Name $rgName -Location $locName

Get-AzureRmResourceGroup | Sort ResourceGroupName | Select ResourceGroupName

#Test to make sure storage account exists
#Test-AzureName -Storage $storageName

New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName

#region Obtain Azure Storage Context
$storageAccountKey = (Get-AzureStorageKey $storageAccountName).Primary
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -Protocol https 

#endregion

# Copy the BakeryWebsite folder into the xWebAdministration folder so it is zipped up as a resource to be deployed to Azure
Copy-Item "..\Source\BakeryWebsite" $contentInstallPath -Recurse

#region Publish the VM DSC configuration
# Typically, what you would do is just zip up the contents of the package and place it immediately into Storage. In 
# our case, we need to build a zip file that contains our web Source code. 
Publish-AzureVMDscConfiguration $configurationScript -ConfigurationArchivePath $configurationArchive -Force -Verbose

Publish-AzureVMDscConfiguration $configurationArchive -Force -Verbose

#endregion

#region Initialize arguments for Set-AzureVMDscExtension


$configurationArgument = @{
    websiteSourceLocation = $websiteSourceLocation;
}

$configurationDataPath = Join-Path $currentDirectory "ConfigurationData.psd1"

# Arguments for Set-AzureVMDscExtension
$arguments = @{
    Version = $dscExtensionVersion;
    StorageContext = $storageContext;
    ConfigurationArchive = $configurationArchive;
    ConfigurationName = $configurationName;
    ConfigurationArgument = $configurationArgument
    ConfigurationDataPath = $configurationDataPath
}

#endregion

Test-AzureRmDnsAvailability -DomainQualifiedName $domName -Location $locName

New-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName -Location $locName

Get-AzureRmAvailabilitySet –ResourceGroupName $rgName | Sort Name | Select Name

$frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24

$backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.2.0/24

New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 `
-Subnet $frontendSubnet,$backendSubnet

Get-AzureRmVirtualNetwork -ResourceGroupName $rgName | Sort Name | Select Name

$publicIP = New-AzureRmPublicIpAddress -Name $publicipname -ResourceGroupName $rgName -Location $locName `
–AllocationMethod Dynamic -DomainNameLabel $domName

Get-AzureRMPublicIPAddress –Name $publicipname –ResourceGroupName $rgName

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-Frontend -PublicIpAddress $publicIP

$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-backend"

$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP1" -FrontendIpConfiguration $frontendIP `
-Protocol TCP -FrontendPort 3441 -BackendPort 3389
 
 $inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP2" -FrontendIpConfiguration $frontendIP `
 -Protocol TCP -FrontendPort 3442 -BackendPort 3389

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "HealthProbe.aspx" `
-Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$Lab5LB = New-AzureRmLoadBalancer -ResourceGroupName $rgName -Name $lbName -Location $locName -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1,$inboundNatRule2 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe

# Set the existing virtual network and subnet index
$subnetIndex=0
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName

$bePoolIndex=0
$natRuleIndex=0
$lb=Get-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName
$nic=New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName `
-Subnet $vnet.Subnets[$subnetIndex] -LoadBalancerBackendAddressPool $lb.BackendAddressPools[$bePoolIndex] `
-LoadBalancerInboundNatRule $lb.InboundNatRules[$natRuleIndex]

# Specify the name, size, and existing availability set

$avSet=Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avName

#region Apply the Extension to the VM
# Get the instance of the VM
$vm = Get-AzureVM -ServiceName $vmServiceName -Name $vmName -ErrorAction SilentlyContinue

if ($vm)
{
    # VM already exists, so apply the configuration using the Extension
    $vm | Set-AzureVMDSCExtension @arguments -Verbose | Update-AzureRmVM -ResourceGroupName $rgName
}
else
{
    # VM does not exist. Initialize the provisioning config
    $vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id

    $storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName

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

        
    # Set the DSC Extension properties on the VM object, Create a new VM
    $vm | Set-AzureVMDSCExtension @arguments -Verbose | New-AzureRmVM -ResourceGroupName $rgName -Location $locName -WaitForBoot
}

#Now that the script has completed, remove the Bakery website from the DSC resources directory
Remove-Item (Join-Path $contentInstallPath "\BakeryWebsite") –Recurse


