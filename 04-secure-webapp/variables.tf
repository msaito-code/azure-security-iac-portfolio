variable "location" {
	description 	= "Azure region for resources"
	type		= string
	default		= "eastus"
}

variable "prefix" {
	description	= "Prefix for resource naming"
	type		= string
	default		= "portf-secweb"
}

variable "vnet_address-space" {
	description	= "Address space for the VNet"
	type		= list(string)
	default		= ["10.1.0.0/16"]
}

variable "appgw_subnet_prefix" {
	description	= "Address prefix for the App Gateway subnet"
	type		= string
	default		= "10.1.1.0/24"
}

variable "pe_subnet_prefix" {
	description	= "Address prefix for the Private Endpoint subnet"
	type		= string
	default		= "10.1.2.0/24"
}
