# Creating AKS Resource Group
resource "azurerm_resource_group" "aks_rg" {
	name	 = "rg-aks-workload-portfolio"
	location = var.location
	tags	 = local.common_tags
}

# Create User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks_identity" {
	name			= "id-aks-control-plane"
	location		= azurerm_resource_group.aks_rg.location
	resource_group_name	= azurerm_resource_group.aks_rg.name
	tags			= local.common_tags
}

# Grant Private DNS Zone Contributor role to the User Assigned Identity for DNS updates
resource "azurerm_role_assignment" "aks_dns_contributor" {
	scope					= azurerm_private_dns_zone.aks_dns.id
	role_definition_name			= "Private DNS Zone Contributor"
	principal_id				= azurerm_user_assigned_identity.aks_identity.principal_id
	principal_type				= "ServicePrincipal"
	skip_service_principal_aad_check	= true
}

# Grant Private DNS Zone Contributor role to the Managed Identity for DNS updates
resource "azurerm_kubernetes_cluster" "private_aks" {
	name			= "aks-spoke1-${var.location}"
	location		= azurerm_resource_group.aks_rg.location
	resource_group_name	= azurerm_resource_group.aks_rg.name
	dns_prefix		= "aks-spoke1"

	private_cluster_enabled 		= true
	private_cluster_public_fqdn_enabled	= false
	private_dns_zone_id			= azurerm_private_dns_zone.aks_dns.id

	oidc_issuer_enabled			= true
	workload_identity_enabled		= false
	role_based_access_control_enabled	= true

	# Assign User Assigned identity for control plane operations
	identity {
		type		= "UserAssigned"
		identity_ids	= [azurerm_user_assigned_identity.aks_identity.id]
	}

	azure_active_directory_role_based_access_control {
		azure_rbac_enabled	= true
		admin_group_object_ids	= var.aks_admin_group_object_ids
	}

	default_node_pool {
		name			= "systempool"
		vm_size			= "Standard_D2s_v7"
		vnet_subnet_id		= azurerm_subnet.spoke1_subnet.id
		auto_scaling_enabled	= true
		min_count		= 1
		max_count		= 3
		os_disk_type		= "Managed"

		# Restrict system node pool to system critical workloads
		only_critical_addons_enabled = true
		upgrade_settings {
			max_surge = "33%"
		}
	}

	network_profile {
		network_plugin = "azure"
		network_policy = "calico"

		# Leverage the existing UDR route (0.0.0.0/0 -> Azure Firewall)
		outbound_type  = "userDefinedRouting"
	}

	dynamic "oms_agent" {
		for_each = var.enable_monitoring ? [1]: []
		content {
			log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
		}
	}

	depends_on = [
		azurerm_role_assignment.aks_dns_contributor,
		azurerm_subnet_route_table_association.spoke1_rt_assoc,
		azurerm_firewall_application_rule_collection.aks_app_rules,
		azurerm_firewall_network_rule_collection.aks_required_rules
	]

	tags = merge(local.common_tags, { Role = "Kubernetes"})
	}
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
	count			= var.enable_workload_node_pool ? 1 : 0
	name			= "workload"
	kubernetes_cluster_id	= azurerm_kubernetes_cluster.private_aks.id
	vm_size			= "Standard_D2s_v7"
	vnet_subnet_id		= azurerm_subnet.spoke1_subnet.id
	mode			= "User"
	auto_scaling_enabled	= true
	min_count		= 1
	max_count		= 3
	os_disk_type		= "Managed"

	upgrade_settings {
		max_surge = "33%"
	}

	tags = merge(local.common_tags, { Role = "Workload" })
}
