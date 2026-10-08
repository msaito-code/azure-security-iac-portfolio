# Random string to ensure unique App Service name
resource "random_string" "suffix" {
	length	= 6
	special	= false
	upper	= false
}

# Application Gateway Public IP
resource "azurerm_public_ip" "appgw_ip" {
	name			= "pip-appgw-${var.prefix}"
	location		= azurerm_resource_group.app_rg.location
	resource_group_name	= azurerm_resource_group.app_rg.name
	allocation_method	= "Static"
	sku			= "Standard"
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "waf_policy" {
	name			= "wafpol-${var.prefix}"
	location		= azurerm_resource_group.app_rg.location
	resource_group_name	= azurerm_resource_group.app_rg.name

	policy_settings {
		enabled				= true
		mode				= "Prevention"
		request_body_check		= true
		file_upload_limit_in_mb 	= 100
		max_request_body_size_in_kb	= 128
	}

	managed_rules {
		managed_rule_set {
			type = "OWASP" # Conseider OWASP Top 10 most critical security risks to web applications
			version = "3.2"
		}
	}
}

# Application Gateway
resource "azurerm_application_gateway" "appgw" {
	name			= "agw-${var.prefix}"
	location		= azurerm_resource_group.app_rg.location
	resource_group_name	= azurerm_resource_group.app_rg.name

	sku {
		name	 = "WAF_v2"
		tier	 = "WAF_v2"
		capacity = 2
	}

	gateway_ip_configuration {
		name		= "appgw-ip-config"
		subnet_id	= azurerm_subnet.appgw_subnet.id
	}

	frontend_port {
		name = "fe-port-80"
		port = 80
	}

	frontend_ip_configuration {
		name			= "fe-ip-config"
		public_ip_address_id	= azurerm_public_ip.appgw_ip.id
	}

	backend_address_pool {
		name	= "appservice-backend"
		fqdns	= [azurerm_linux_web_app.app.default_hostname]
	}

	backend_http_settings {
		name					= "http-settings"
		cookie_based_affinity			= "Disabled"
		port					= 443 # Communicating securely to the backend
		protocol				= "Https"
		request_timeout				= 60
		pick_host_name_from_backend_address	= true
	}

	http_listener {
		name				= "http-listener"
		frontend_ip_configuration_name	= "fe-ip-config"
		frontend_port_name		= "fe-port-80"
		protocol			= "Http"
	}

	request_routing_rule {
		name				= "routing_rule"
		rule_type			= "Basic"
		http_listener_name		= "http-listener"
		backend_address_pool_name	= "appservice-backend"
		backend_http_settings_name	= "http-settings"
		priority			= 100
	}

	firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

	#Ensure the AppGW resolves the private DNS zone by depending on the link
	depends_on = [azurerm_private_dns_zone_virtual_network_link.vnet_link]
}

# App Service Plan (Premium SKU required for Private Endpoints)
resource "azurerm_service_plan" "asp" {
	name			= "asp-${var.prefix}"
	location		= azurerm_resource_group.app_rg.location
	resource_group_name	= azurerm_resource_group.app_rg.name
	os_type			= "Linux"
	sku_name		= "P0v3"
}

# Linux Web App
resource "azurerm_linux_web_app" "app" {
	name			= "app-${var.prefix}-${random_string.suffix.result}"
	location		= azurerm_service_plan.asp.location
	resource_group_name	= azurerm_resource_group.app_rg.name
	service_plan_id		= azurerm_service_plan.asp.id

	# CRITICAL: Disable public internet access
	public_network_access_enabled = false

	site_config {
		always_on = true
	}
}

# Private Endpoint for App Service
resource "azurerm_private_endpoint" "app_pe" {
	name			= "pe-${azurerm_linux_web_app.app.name}"
	location		= azurerm_resource_group.app_rg.location
	resource_group_name	= azurerm_resource_group.app_rg.name
	subnet_id		= azurerm_subnet.pe_subnet.id

	private_service_connection {
		name				= "psc-app"
		private_connection_resource_id	= azurerm_linux_web_app.app.id
		subresource_names		= ["sites"]
		is_manual_connection		= false
	}

	private_dns_zone_group {
		name			= "dns-zone-group"
		private_dns_zone_ids	= [azurerm_private_dns_zone.appservice_zone.id]
	}
}
