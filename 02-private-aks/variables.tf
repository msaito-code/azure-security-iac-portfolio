variable "location" {
	description 	= "Azure region for resources"
	type	     	= string
	default	     	= "eastus"

	validation {
		condition	= var.location == lower(var.location)
		error_message	= "location must use a lowercase Azure region identifier, such as eastus"
	}
}

variable "hub_address_space" {
	description 	= "Address space for the Hub VNet"
	type		= list(string)
	default		= ["10.0.0.0/16"] 
}

variable "spoke1_address_space" {
	description	= "Address space for the Spoke 1 VNet"
	type		= list(string)
	default		= ["10.1.0.0/16"]
}

variable "spoke2_address_space" {
	description	= "Address space for the Spoke 2 VNet"
	type		= list(string)
	default		= ["10.2.0.0/16"]
}

variable "aks_subnet_prefixes" {
	description	= "Address prefixes for the AKS node subnet."
	type		= list(string)
	default		= ["10.1.0.0/24"]
}

variable "spoke2_subnet_prefixes" {
	description	= "Address previxes for the second spoke workload subnet."
	type		= list(string)
	default		= ["10.2.0.0/24"]
}

variable "enable_workload_node_pool" {
	description	= "Create a separate user node pool for application workloads"
	type		= bool
	default		= false
}

variable "enable_monitoring" {
	description	= "Create a Log Analytics workspace and enable AKS monitoring."
	type		= bool
	default		= false
}

variable "aks_admin_group_object_ids" {
	description 	= "Microsoft Entra group object IDs that administer the AKS cluster. Keep empty for Azure RBAC-only assignments managed separately."
	type		= list(string)
	default		= []
}
