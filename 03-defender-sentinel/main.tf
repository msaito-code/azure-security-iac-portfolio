# Create Log Analytics Resource Group
resource "azurerm_resource_group" "sentinel_rg" {
	name		= "sentinel-soc-prod-rg"
	location	= "eastus"
}

# Create the Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log" {
	name			= "log-sentinel-workspace-01"
	location		= azurerm_resource_group.sentinel_rg.location
	resource_group_name	= azurerm_resource_group.sentinel_rg.name
	sku			= "PerGB2018"
	retention_in_days	= 30
}
