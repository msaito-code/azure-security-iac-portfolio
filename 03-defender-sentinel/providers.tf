# 0. Terraform settings and provideris
terraform {
	required_providers {
		azurerm = {
			source 	= "hashicorp/azurerm"
			version = "~> 4.0"
		}
	}

	backend "azurerm" {
		resource_group_name	= "rg-terraform-state-sec-portfolio"
		storage_account_name	= "tfstatesec61bb283b"
		container_name		= "tfstate"
		key			= "portfolio.terraform.tfstate"
	}
}

provider "azurerm" {
	features {}
}
