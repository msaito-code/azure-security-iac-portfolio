# 🛡️ Secure Web App with Application Gateway & WAF

This project demonstrates the deployment of a highly secure Azure App Service architecture. Instead of exposing the web application directly to the internet, all ingress traffic is routed through an **Azure Application Gateway (WAF_v2)**. The App Service itself is completely isolated from the public internet using **Azure Private Endpoints**.

## 🏗️ Architecture Overview

1. **User Ingress:** Users access the application via the Application Gateway's Public IP.
2. **Threat Protection:** The Web Application Firewall (WAF) inspects incoming traffic against the **OWASP 3.2** core ruleset, blocking SQL injection, Cross-Site Scripting (XSS), and other common web vulnerabilities in *Prevention* mode.
3. **Private Connectivity:** The Application Gateway routes legitimate traffic to the App Service via an **Azure Private Endpoint** (Azure Private Link). 
4. **Zero Trust:** The App Service has `public_network_access_enabled` set to `false`. It cannot be accessed directly from the internet, bypassing the WAF is impossible.

## ⚙️ Resources Deployed

* **Virtual Network (VNet):** Segregated subnets for the Application Gateway and Private Endpoints.
* **Public IP (Standard):** The frontend entry point for the Application Gateway.
* **Application Gateway (WAF_v2):** Regional load balancer with WAF enabled.
* **WAF Policy:** Global WAF configuration defining rules and thresholds.
* **App Service Plan & Linux Web App:** The backend hosting the application (Premium SKU required for Private Endpoint support).
* **Private Endpoint & Private DNS Zone:** Maps `privatelink.azurewebsites.net` to the VNet to ensure internal routing from the App Gateway to the Web App.

## 🚀 Deployment Instructions

### Prerequisites
* [Terraform](https://www.terraform.io/downloads.html) installed (v1.0+).
* Azure CLI installed and authenticated (`az login`).
* An active Azure Subscription.
