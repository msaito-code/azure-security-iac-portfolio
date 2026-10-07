# 8. API Connection for Microsoft Sentinel
resource "azurerm_api_connection" "sentinel_api" {
	name			= "sentinel-connection"
#	location		= azurerm_resource_group.sentinel_rg.location
	resource_group_name	= azurerm_resource_group.sentinel_rg.name
	managed_api_id		= "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.sentinel_rg.location}/managedApis/azuresentinel"

	# Note: Post-deployment, an admin must click "Authorize" in the Azure Portal for this connection
}

# 9. API Connection for Microsoft Entra ID (to disable the compromised user)
resource "azurerm_api_connection" "azuread_api" {
	name			= "azuread-connection"
#	location		= azurerm_resource_group.sentinel_rg.location
	resource_group_name	= azurerm_resource_group.sentinel_rg.name
	managed_api_id		= "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.sentinel_rg.location}/managedApis/azuread"
}
