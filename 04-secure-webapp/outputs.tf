output "resource_group_name" {
	description 	= "The name of the Resource Group"
	value		= azurerm_resource_group.app_rg.name
}

output "application_gateway_public_ip" {
	description 	= "The public IP address of the Applciation Gateway"
	value		= azurerm_public_ip.appgw_ip.ip_address
}

output "app_service_default_hostname" {
	description	= "The default hostname of the App Service (should be inaccessible publicly)"
	value		= azurerm_linux_web_app.app.default_hostname
}
