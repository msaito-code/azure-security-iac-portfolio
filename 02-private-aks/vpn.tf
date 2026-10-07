# 10. The mandatory Gateway Subnet in the Hub
resource "azurerm_subnet" "gateway_subnet" {
	name			= "GatewaySubnet" # This exact name is required by Azure
	resource_group_name	= azurerm_resource_group.network_rg.name
	virtual_network_name	= azurerm_virtual_network.hub_vnet.name
	address_prefixes	= ["10.0.2.0/27"]
}

# 11. Public IP for the VPN Gateway
resource "azurerm_public_ip" "vpn_gw_pip" {
	name			= "pip-hub-vpngw"
	location		= azurerm_resource_group.network_rg.location
	resource_group_name	= azurerm_resource_group.network_rg.name
	allocation_method	= "Static"
	sku			= "Standard"
}

# 12. The Virtual Network Gateway (Note: This resource takes 30-45 minutes to deploy)
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
	name			= "vgw-hub-eastus"
	location		= azurerm_resource_group.network_rg.location
	resource_group_name	= azurerm_resource_group.network_rg.name

	type			= "Vpn"
	vpn_type		= "RouteBased"
	sku			= "VpnGw1AZ" # Cost-effective tier that supports OpenVPN

	ip_configuration {
		name				= "vnetGatewayConfig"
		public_ip_address_id		= azurerm_public_ip.vpn_gw_pip.id
		private_ip_address_allocation	= "Dynamic"
		subnet_id			= azurerm_subnet.gateway_subnet.id
	}

	# Point-to-Site Configuration
	vpn_client_configuration {
		address_space		= ["172.16.0.0/24"] # IPs assigned to connect VPN clients
		vpn_client_protocols	= ["OpenVPN"]

		# Azure authentication the Linux client using this Root Certificate
		root_certificate {
			name		 = "P2SRootCert"
			public_cert_data = local.vpn_root_cert_base64
		}
	}
}
