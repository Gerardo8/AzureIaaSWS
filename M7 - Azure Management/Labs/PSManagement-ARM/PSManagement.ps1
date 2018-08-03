$subscr="[Your-subscription-Name]"
$rgName = "[Your-resourcegroup-name]"
$locName = "[Region]"
$saName = "[Your-storage-account-name]"
$saType="Standard_LRS"
$domName = "[Your-domain-name]"
$avName = "[Your-availability-set-name]"
$vnetName = "[Your-virtual-network-name]"
$publicipname = "[Your-publicIP-address-name]"
$lbName = "[Your-load-balancer-name"

Login-AzureRmAccount

Get-AzureRmSubscription | Sort SubscriptionName | Select SubscriptionName

Get-AzureRmSubscription –SubscriptionName $subscr | Select-AzureRmSubscription
New-AzureRmResourceGroup -Name $rgName -Location $locName

Get-AzureRmResourceGroup | Sort ResourceGroupName | Select ResourceGroupName

#Test to make sure storage account exists
Test-AzureName -Storage $storageName

New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName

Test-AzureRmDnsAvailability -DomainQualifiedName $domName -Location $locName

New-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName -Location $locName

Get-AzureRmAvailabilitySet –ResourceGroupName $rgName | Sort Name | Select Name

$frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24

$backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.2.0/24

New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $frontendSubnet,$backendSubnet

Get-AzureRmVirtualNetwork -ResourceGroupName $rgName | Sort Name | Select Name

$publicIP = New-AzureRmPublicIpAddress -Name $publicipname -ResourceGroupName $rgName -Location $locName –AllocationMethod Dynamic -DomainNameLabel $domName

Get-AzureRMPublicIPAddress –Name $publicipname –ResourceGroupName $rgName

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-Frontend -PublicIpAddress $publicIP

$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-backend"

$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP1" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3441 -BackendPort 3389
 
$inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP2" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3442 -BackendPort 3389

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "/" -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$Lab5LB = New-AzureRmLoadBalancer -ResourceGroupName $rgName -Name $lbName -Location $locName -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1,$inboundNatRule2 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe







