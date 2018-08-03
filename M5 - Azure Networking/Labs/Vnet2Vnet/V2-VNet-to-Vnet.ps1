# From MSDN article https://azure.microsoft.com/en-us/documentation/articles/vpn-gateway-vnet-vnet-rm-ps/
# Values for the VNets
# Values for VNet1: 
# •Virtual Network Name = vnetEast
# •Resource Group = rgEast
# •Address Space = 10.1.0.0/16 
# •Region = US East
# •GatewaySubnet = 10.1.0.0/28
# •Subnet1 = 10.1.1.0/28

# Values for VNet2: 
# •Virtual Network Name = vnetCentral
# •Resource Group = rgCentral
# •Address Space = 10.2.0.0/16
# •Region = US Central
# •GatewaySubnet = 10.2.0.0/28
# •Subnet1 = 10.2.1.0/28

$vnet1 = 'vnetEast'
$rg1 = 'rgEast'
$addsp1 = '10.1.0.0/16'
$loc1 = 'East US'
$gwsubnet1 = '10.1.0.0/28'
$appsubnet1 = '10.1.1.0/28'

$vnet2 = 'vnetCentral'
$rg2 = 'rgCentral'
$addsp2 = '10.2.0.0/16'
$loc2 = 'East US'
$gwsubnet2 = '10.2.0.0/28'
$appsubnet2 = '10.2.1.0/28'

#Install-Module AzureRM
#Install-AzureRM
#Import-AzureRM

#Login-AzureRmAccount
#Get-AzureRmSubscription
#Select-AzureRmSubscription -Subscriptionid "GUID of subscription"

#Create the virtual network
New-AzureRmResourceGroup -Name $rg1 -Location $loc1

$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $gwsubnet1
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'AppSubnet' -AddressPrefi $appsubnet1
New-AzureRmVirtualNetwork -Name $vnet1 -ResourceGroupName $rg1 -Location $loc1 -AddressPrefix $addsp1 -Subnet $subnet, $subnet1

# Request a public IP address
$gwpip1= New-AzureRmPublicIpAddress -Name gwpip1 -ResourceGroupName $rg1 -Location $loc1 -AllocationMethod Dynamic

#Create the gateway configuration
$vnet = Get-AzureRmVirtualNetwork -Name $vnet1 -ResourceGroupName $rg1
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip1.Id 

# Create the GAteway
New-AzureRmVirtualNetworkGateway -Name vnetgw1 -ResourceGroupName $rg1 -Location $loc1 -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased

# Create 2nd VNet
New-AzureRmResourceGroup -Name $rg2 -Location $loc2

$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $gwsubnet2
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'AppSubnet' -AddressPrefi $appsubnet2
New-AzureRmVirtualNetwork -Name $vnet2 -ResourceGroupName $rg2 -Location $loc2 -AddressPrefix $addsp2 -Subnet $subnet, $subnet1

# Request a public IP address
$gwpip2= New-AzureRmPublicIpAddress -Name gwpip2 -ResourceGroupName $rg2 -Location $loc2 -AllocationMethod Dynamic

#Create the gateway configuration
$vnet = Get-AzureRmVirtualNetwork -Name $vnet2 -ResourceGroupName $rg2
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name gwipconfig2 -SubnetId $subnet.Id -PublicIpAddressId $gwpip2.Id 

# Create the GAteway
New-AzureRmVirtualNetworkGateway -Name vnetgw2 -ResourceGroupName $rg2 -Location $loc2 -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased


# Connect the gateways
$vnetgw1 = Get-AzureRmVirtualNetworkGateway -Name vnetgw1 -ResourceGroupName $rg1
$vnetgw2 = Get-AzureRmVirtualNetworkGateway -Name vnetgw2 -ResourceGroupName $rg2

New-AzureRmVirtualNetworkGatewayConnection -Name conn1 -ResourceGroupName $rg1 -VirtualNetworkGateway1 $vnetgw1 -VirtualNetworkGateway2 $vnetgw2 -Location $loc1 -ConnectionType Vnet2Vnet -SharedKey 'abc123'

# Connect the gateways
$vnetgw1 = Get-AzureRmVirtualNetworkGateway -Name vnetgw2 -ResourceGroupName $rg2
$vnetgw2 = Get-AzureRmVirtualNetworkGateway -Name vnetgw1 -ResourceGroupName $rg1


New-AzureRmVirtualNetworkGatewayConnection -Name conn2 -ResourceGroupName $rg2 -VirtualNetworkGateway1 $vnetgw1 -VirtualNetworkGateway2 $vnetgw2 -Location $loc2 -ConnectionType Vnet2Vnet -SharedKey 'abc123'

# Verify Connections
# Verify VNet 1 connection to VNet 2
Get-AzureRmVirtualNetworkGatewayConnection -Name conn1 -ResourceGroupName $rg1 -Debug 

# Verify VNet 2 connection to VNet 1
Get-AzureRmVirtualNetworkGatewayConnection -Name conn2 -ResourceGroupName $rg2 -Debug 




