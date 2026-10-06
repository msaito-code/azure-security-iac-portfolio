# 6. Empty Logic App shell (Playbook logic is usually deployed via ARM template within this workflow)
resource "azurerm_logic_app_workflow" "playbook" {
	name			= "sentinel-playbook-block-ip"
	location		= azurerm_resource_group.sentinel_rg.location
	resoure_group_name	= azurerm_resource_group.sentinel_rg.name

	# Map the Logic App to the API connections created in connection.tf
	workflow_parameters = {
		"$connection" = jsonencode({
			azuresentinel ={
				connectionId 	= azurerm_api_connection.sentinel_api.id
				connectionName 	= "azuresentinel"
				id		= "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.sentinel_rg.location}/managedApis/azuresentinel"
			}
			azuread = {
				connectionId	= azurerm_api_connection.azuread_api.id
				connectionName	= "azuread"
				id		= "/subscription/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/lcoations/${azurerm_resource_group.sentinel_rg.location}/managedApis/azuread"
			}
		})
	}
}

# 10. Attach the JSON workflow definition
resource "azurerm_logic_app_action_custom" "workflow_logic" {
	name		= "workflow-deployment"
	logic_app_id	= azurerm_logic_app_workflow.playbook.id
	body		= file("${path.module}/playbook.json")
}

# 7. Automation rule linking the Incident to the Playbook
resource "azurerm_sentinel_automation_rule" "playbook_rule" {
	name				= "56094f72-ac3f-40e7-a0c0-47bf96571110" # Must be an UUID
	log_analytics_workspace_id 	= azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
	display_name			= "Automated IP blocking remediation"
	order				= 1

	action_playbook {
		logic_app_id 	= azurerm_logic_app_workflow.playbook.id
		order 		= 1
	}

	condition {
		operator = "Contains"
		property = "IncidentTitle"
		values	 = ["Detect Multiple Failed Sign-ins"]
	}
}
