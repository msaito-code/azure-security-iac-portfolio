locals {
	aks_private_dns_zone_name = "privatelink.${var.location}.azmk8s.io"

	common_tags = {
		Environment	= "Portfolio"
		ManagedBy	= "Terraform"
		Project		= "Private-AKS"
	}
}
