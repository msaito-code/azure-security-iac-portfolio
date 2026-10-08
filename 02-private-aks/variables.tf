variable "location" {
	description 	= "Azure region for resources"
	type	     	= string
	default	     	= "eastus"
}

variable "hub_address_space" {
	description 	= "Address space for the Hub VNet"
	type		= list(string)
	default		= ["10.0.0.0/16"] 
}

variables "spoke1_address_space" {
	description	= "Address space for the Spoke 1 VNet"
	type		= list(string)
	default		= ["10.1.0.0/16"]
}

variables "spoke2_address_space" {
	description	= "Address space for the Spoke 2 VNet"
	type		= list(string)
	default		= ["10.2.0.0/16"]
}
