# 1 -- Resource group
# Create resource group
$rg = @{
    Name = 'RG-USE-Nextcloud'
    Location = 'eastus'
}
New-AzResourceGroup @rg

# 2 -- Virtual Network
# Create virtual network
$vnet = @{
    Name = 'VNET-USE-Nextcloud'
    ResourceGroupName = 'RG-USE-Nextcloud'
    Location = 'eastus'
    AddressPrefix = '172.10.0.0/16'
}
$virtualNetwork = New-AzVirtualNetwork @vnet

# Create subnet for virtual network
$subnet = @{
    Name = 'SNET-USE-Nextcloud'
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '172.10.0.0/24'
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnet
# Associate subnet configuration to virtual network
$virtualNetwork | Set-AzVirtualNetwork

# 3 -- Network security group
# Create NSG
New-AzNetworkSecurityGroup -Name NSG-USE-Nextcloud -ResourceGroupName RG-USE-Nextcloud  -Location  eastus
# Associate NSG to Virtual Network subnet
# Place the network security group configuration into a variable. ##
$networkSecurityGroup = Get-AzNetworkSecurityGroup -Name NSG-USE-Nextcloud -ResourceGroupName RG-USE-Nextcloud
# Update the subnet configuration. ##
Set-AzVirtualNetworkSubnetConfig -Name SNET-USE-Nextcloud -VirtualNetwork $virtualNetwork -AddressPrefix 172.10.0.0/24 -NetworkSecurityGroup $networkSecurityGroup
# Update the virtual network. ##
Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork

# Use this line before Bastion if shell is reset and lose variables
$virtualNetwork = Get-AzVirtualNetwork -Name VNET-USE-Nextcloud -ResourceGroupName RG-USE-Nextcloud

# 4 -- Bastion
# Create Bastion subnet
$bastionSubnet = @{
    Name = 'AzureBastionSubnet'
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '172.10.1.0/24'
}
$bastionSubnetConfig = Add-AzVirtualNetworkSubnetConfig @bastionSubnet
# Set the configuration
$virtualNetwork | Set-AzVirtualNetwork
# Create Public ip for Bastion
$publicip = New-AzPublicIpAddress -ResourceGroupName "RG-USE-Nextcloud" `
-name "BASTIONIP-USE-Nextcloud" -location "EastUS" `
-AllocationMethod Static -Sku Standard
# Create Bastion resource
New-AzBastion -ResourceGroupName "RG-USE-Nextcloud" -Name "BASTION-USE-Nextcloud" `
-PublicIpAddressRgName "RG-USE-Nextcloud" -PublicIpAddressName "BASTIONIP-USE-Nextcloud" `
-VirtualNetworkRgName "RG-USE-Nextcloud" -VirtualNetworkName "VNET-USE-Nextcloud" `

# 5 -- Virtual Machine Configuration
## Resource group and virtual network should be populated as above, if not done automatically
## Location: US East | Image: Unbuntu Server 18.04 LTS - Gen 1 | Size: Standard_B1s
## Admin Acount > Auth type: SSH public key | Username: edgar | Key source: Generate new file 
##                Key pair name: VNET-USE-Nextcloud_sshkey 
## Inboud port rules > change to none; so that it's not accessible to users on public internet
## Next [Disks] > leave as default
## Next [Networking] > Public IP has been automatically generated
## [Review + create]
## Download ssh key when prompted

#6 -- Nextcloud Setup
## Connect via Bastion > using local SSH key file 
## Install Nextclod
# sudo snap install nextcloud
## Create simple admin account
# sudo nextcloud.manual-install admin edgar
## Create self-signed certificate
# sudo nextcloud.enable-https self-signed
## Exit Bastion instance
#exit

#7 -- VM Network Change
## Add inbound security rule
## Source: My IP address | Destination: IP Addresses | Destination IP: 172.10.0.4
## Service: HTTPS | Action: Allow | Name: HTTPS_Nextcloud
## Server should respond when navigating to IP on browser

#8 -- Add domain to public IP
## Go to Public IP resource > Configuration
## DNS name label > edgarnextcloud [type here desired DNS]

#9 -- Communicate DNS label change to Nextcloud server
## Connect via Bastion SSH
## Set DNS domain
# sudo nextcloud.occ config:system:set trusted_domains 1 -- value=edgarnextcloud.eastus.cloudapp.azure.com