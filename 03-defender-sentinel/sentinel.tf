# 3. Onboard Sentinel to the Log Analytics Workspace
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
	workspace_id	= azurerm_log_analytics_workspace.log.id
}

# 4. Connect EntraID Logs (Simulating identity/network access logs)
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
	name				= "aad-connector"
	log_analytics_workspace_id	= azurerm_log_analytics_workspace.log.id
	tenant_id			= data.azurerm_client_config.current.tenant_id
}

# 5. KQL Analytics Rule: Detect Brite Force / Malicious Sign-ins
resource "azurerm_sentinel_alert_rule_scheduled" "detect_anomaly" {
	name				= "detect-brute-force-01"
	log_analytics_workspace_id	= azurerm_log_analytics_workspace.log.id
	display_name			= "Detect Multiple Failed Sign-ins"
	severity			= "High"
	
	query = <<KQL
		SigninLogs
		| where ResultType != "0"
		| summarize count() by UserPrincipalName, IPAddress
		| where count_ > 10
	KQL

	query_frequency 		= "PT1H"
	query_period			= "PT1H"
	trigger_operator		= "GreaterThan"
	trigger_threshold		= 0
	suppression_enabled		= false

	incident {
		create_incident_enabled = true
		grouping {
			enabled = true
		}
	}
	
	depends_on = [
		azurerm_sentinel_log_analytics_workspace_onboarding.sentinel
	]
}
