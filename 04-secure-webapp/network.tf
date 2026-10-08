resource "azurerm_resource_group" "app_rg" {
	name	 = "${var.prefix}-${var.location}-rg"
	location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
	name			= "vnet-${var.prefix}"
	location		= azurerm_resource_group.app_rg.location
	resource_group_name	= azurerm_resource_group.app_rg.name
	address_space		= var.vnet_address_space
}

# Subnet for Appliaction Gateway
resource "azurerm_subnet" "appgw_subnet" {
	name			= "snet-appgw"
	resource_group_name	= azurerm_resource_group.app_rg.name
	virtual_network_name	= azurerm_virtual_network.vnet.name
	address_prefixes	= [var.appgw_subnet_prefix]
}

# Subnet for Private Endpoint
resource "azurerm_subnet" "pe_subnet" {
	name			= "snet-pe"
	resource_group_name	= azurerm_resource_group.app_rg.name
	virtual_network_name	= azurerm_virtual_network.vnet.name
	address_prefixes	= [var.pe_subnet_prefix]
}

# Private DNS Zone for App Service
resource "azurerm_private_dns_zone" "appservice_zone" {
	name			= "privatelink.azurewebsites.net"
	resource_group_name	= azurerm_resource_group.app_rg.name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
	name			= "link-dns-vnet"
	resource_group_name	= azurerm_resource_group.app_rg.name
	private_dns_zone_name	= azurerm_private_dns_zone.appservice_zone.name
	virtual_network_id	= azurerm_virtual_network.vnet.id
}
