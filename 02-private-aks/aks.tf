i 4. Creating AKS Resource Group
resource "azurerm_resource_group" "aks_rg" {
	name	 = "rg-aks-workload-portfolio"
	location = var.location
}

# 5. Create User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks_identity" {
	name			= "id-aks-control-plane"
	location		= azurerm_resource_group.aks_rg.location
	resource_group_name	= azurerm_resource_group.aks_rg.name
}

# 6. Grant Private DNS Zone Contributor role to the User Assigned Identity for DNS updates
resource "azurerm_role_assignment" "aks_dns_contributor" {
	scope			= azurerm_private_dns_zone.aks_dns.id
	role_definition_name	= "Private DNS Zone Contributor"
	principal_id		= azurerm_user_assigned_identity.aks_identity.principal_id
}

# 7. Grant Private DNS Zone Contributor role to the Managed Identity for DNS updates
resource "azurerm_kubernetes_cluster" "private_aks" {
	name			= "aks-spoke1-${azurerm_resource_group.aks_rg.location}"
	location		= azurerm_resource_group.aks_rg.location
	resource_group_name	= azurerm_resource_group.aks_rg.name
	dns_prefix		= "aks-spoke1"
	private_cluster_enabled = true
	private_dns_zone_id	= azurerm_private_dns_zone.aks_dns.id

	# Assign User Assigned identity for control plane operations
	identity {
		type		= "UserAssigned"
		identity_ids	= [azurerm_user_assigned_identity.aks_identity.id]
	}

	default_node_pool {
		name			= "systempool"
		node_count		= 2
		vm_size			= "Standard_D2s_v7"
		vnet_subnet_id		= azurerm_subnet.spoke1_subnet.id
		auto_scaling_enabled	= true
		min_count		= 1
		max_count		= 3
		os_disk_type		= "Managed"

		# Restrict system node pool to system critical workloads
		only_critical_addons_enabled = true
	}

	network_profile {
		network_plugin = "azure"
		network_policy = "calico"

		# Leverage the existing UDR route (0.0.0.0/0 -> Azure Firewall)
		outbound_type  = "userDefinedRouting"
	}

	depends_on = [
		azurerm_role_assignment.aks_dns_contributor
	]

	tags = {
		Enviroment 	= "Production"
		Role		= "Kubernetes"
	}
}
