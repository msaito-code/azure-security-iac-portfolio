# Network Resource Group
resource "azurerm_resource_group" "network_rg" {
	name		= "rg-secure-network-portfolio"
	location	= var.location
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub_vnet" {
	name			= "vnet-hub-eastus"
	location		= azurerm_resource_group.network_rg.location
	resource_group_name 	= azurerm_resource_group.network_rg.name
	address_space 		= var.hub_address_space

	tags = {
		Environemnt 	= "Production"
		Role 		= "Hub"
	}
} 

# Spoke 1 Virtual Network
resource "azurerm_virtual_network" "spoke1_vnet" {
	name			= "vnet-spoke1-eastus"
	location		= azurerm_resource_group.network_rg.location
	resource_group_name	= azurerm_resource_group.network_rg.name
	address_space		= var.spoke1_address_space

	tags = {
		Environment 	= "Production"
		Role 		= "Spoke"
	}
}

# Spoke 2 Virtual Network
resource "azurerm_virtual_network" "spoke2_vnet" {
	name 			= "vnet-spoke2-eastus"
	location		= azurerm_resource_group.network_rg.location
	resource_group_name	= azurerm_resource_group.network_rg.name
	address_space		= var.spoke2_address_space

	tags = {
		Environment = "Production"
		Role = "Spoke"
	}
}

# Peering: Hub to Spoke 1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
	name 				= "peer-hub-to-spoke1"
	resource_group_name		= azurerm_resource_group.network_rg.name
	virtual_network_name		= azurerm_virtual_network.hub_vnet.name
	remote_virtual_network_id	= azurerm_virtual_network.spoke1_vnet.id
	allow_virtual_network_access	= true
	allow_forwarded_traffic		= true
}

# Peering: Spoke 1 to Hub
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
	name				= "peer-spoke1-to-vnet"
	resource_group_name		= azurerm_resource_group.network_rg.name
	virtual_network_name		= azurerm_virtual_network.spoke1_vnet.name
	remote_virtual_network_id	= azurerm_virtual_network.hub_vnet.id
	allow_virtual_network_access	= true
	allow_forwarded_traffic		= true
}

# Peering: Hub to Spoke 2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
	name				= "peer-hub-to-spoke2"
	resource_group_name		= azurerm_resource_group.network_rg.name
	virtual_network_name		= azurerm_virtual_network.hub_vnet.name
	remote_virtual_network_id	= azurerm_virtual_network.spoke2_vnet.id
	allow_virtual_network_access	= true
	allow_forwarded_traffic		= true
}


# Peering: Spoke 2 to Hub
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
	name				= "peer-spoke2-to-vnet"
	resource_group_name		= azurerm_resource_group.network_rg.name
	virtual_network_name		= azurerm_virtual_network.spoke2_vnet.name
	remote_virtual_network_id	= azurerm_virtual_network.hub_vnet.id
	allow_virtual_network_access	= true
	allow_forwarded_traffic		= true
}

# Spoke 1 Workload Subnet
resource "azurerm_subnet" "spoke1_subnet" {
	name 			= "snet-workload-spoke1"
	resource_group_name	= azurerm_resource_group.network_rg.name
	virtual_network_name	= azurerm_virtual_network.spoke1_vnet.name
	address_prefixes	= ["10.1.0.0/24"]
}

# Spoke 2 Workload Subnet
resource "azurerm_subnet" "spoke2_subnet" {
	name			= "snet-workload-spoke2"
	resource_group_name	= azurerm_resource_group.network_rg.name
	virtual_network_name	= azurerm_virtual_network.spoke2_vnet.name
	address_prefixes	= ["10.2.0.0/24"]
}
