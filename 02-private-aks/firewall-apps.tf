# 9. Create MCR Firewall Rules
resource "azurerm_firewall_application_rule_collection" "aks_app_rules" {
	name			= "aks-app-rules"
	azure_firewall_name	= azurerm_firewall.hub_firewall.name
	resource_group_name	= azurerm_resource_group.network_rg.name
	priority		= 200
	action			= "Allow"

	rule {
		name			= "aks-service-traffic"
		source_addresses	= [azurerm_subnet.spoke1_subnet.address_prefixes[0]]

		# The AzureKubernetesService tag automatically includes mcr.microsoft.com
		fqdn_tags		= ["AzureKubernetesService"]
	}
}
