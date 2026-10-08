# 1. Create Private DNS Zone
resource "azurerm_private_dns_zone" "aks_dns" {
	name			= "privatelink.${var.location}.azmk8s.io"
	resource_group_name	= azurerm_resource_group.network_rg.name
}

# 2. Link Private DNS Zone to Spoke 1
resource "azurerm_private_dns_zone_virtual_network_link" "dns_spoke1_link" {
	name			= "link-aks-dns-spoke1"
	resource_group_name	= azurerm_resource_group.network_rg.name
	private_dns_zone_name	= azurerm_private_dns_zone.aks_dns.name
	virtual_network_id	= azurerm_virtual_network.spoke1_vnet.id
}

# 3. Link Private DNS Zone to Hub Vnet (Allows management VMs/jumpboxes in Hub to query AKS API)
resource "azurerm_private_dns_zone_virtual_network_link" "dns_hub_link" {
	name			= "link-aks-dns-hub"
	resource_group_name	= azurerm_resource_group.network_rg.name
	private_dns_zone_name	= azurerm_private_dns_zone.aks_dns.name
	virtual_network_id	= azurerm_virtual_network.hub_vnet.id
}
