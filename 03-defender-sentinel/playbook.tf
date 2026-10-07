# Look up the Microsoft Sentinel background service principal
data "azuread_service_principal" "sentinel_aad" {
	display_name = "Azure Security Insights"
}

# Assign the Automation Contributor role to Sentinel
resource "azurerm_role_assignment" "sentinel_playbook_access" {
	scope			= azurerm_resource_group.sentinel_rg.id
	role_definition_name	= "Microsoft Sentinel Automation Contributor"
	principal_id		= data.azuread_service_principal.sentinel_aad.object_id
}

# Empty Logic App shell (Playbook logic is usually deployed via ARM template within this workflow)
resource "azurerm_resource_group_template_deployment" "playbook" {
	name			= "sentinel-playbook-deployment"
	resource_group_name	= azurerm_resource_group.sentinel_rg.name
	deployment_mode		= "Incremental"

	template_content = jsonencode({
		"$schema": "https://schema.management.azure.com/providers/2019-04-01/deploymentTemplate.json",
		"contentVersion": "1.0.0.0",
		"parameters": {
			"workflowName": { "type": "String" },
			"location": { "type": "String" },
			"sentinelConnectionId": { "type": "String" },
			"azureadConnectionId":  { "type": "String" }
		},
		"resources": [
			{
				"type": "Microsoft.Logic/workflows",
				"apiVersion": "2019-05-01",
				"name": "[parameters('workflowName')]",
				"location": "[parameters('location')]",
				"properties": {
					# Automatically puuls in your playbook.json file
					"definition": jsondecode(file("${path.module}/playbook.json")),
					"parameters": {
						"$connections": {
							"value": {
								"azuresentinel": {

									"connectionId": "[parameters('sentinelConnectionId')]",
									"connectionName": "azuresentinel",
									"id": "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', parameters('location'), '/managedApis/azuresentinel')]"
								},
								"azuread": {
									"connectionId": "[parameters('azureadConnectionId')]",
									"connectionName": "azuread",
									"id": "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', parameters('location'), '/managedApis/azuread')]"
								}
							}
						}
					}
				}
			}
		]
	})

	# Pass the Terraform-generated API connection IDs into the ARM template
	parameters_content = jsonencode({
		"workflowName"		= { "value" = "sentinel-playbook-block-ip" }
		"location"		= { "value" = azurerm_resource_group.sentinel_rg.location }
		"sentinelConnectionId"	= { "value" = azurerm_api_connection.sentinel_api.id }
		"azureadConnectionId"	= { "value" = azurerm_api_connection.azuread_api.id }
	})
}

# Automation rule linking the Incident to the Playbook
resource "azurerm_sentinel_automation_rule" "playbook_rule" {
	name				= "56094f72-ac3f-40e7-a0c0-47bf96571110" # Must be an UUID
	log_analytics_workspace_id 	= azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
	display_name			= "Automated IP blocking remediation"
	order				= 1

	action_playbook {
		logic_app_id 	= "${azurerm_resource_group.sentinel_rg.id}/providers/Microsoft.Logic/workflows/sentinel-playbook-block-ip"
		order 		= 1
	}

	condition_json = jsonencode([
		{
			conditionType = "Property"
			conditionProperties = {
				propertyName 	= "IncidentTitle"
				operator	= "Contains"
				propertyValues	 = ["Detect Multiple Failed Sign-ins"]
			}
		}
	])

	depends_on = [
		azurerm_resource_group_template_deployment.playbook,
		azurerm_role_assignment.sentinel_playbook_access
	]

}
