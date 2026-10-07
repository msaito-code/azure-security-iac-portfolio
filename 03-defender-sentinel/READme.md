# 🛡️ Module: Azure Sentinel SIEM & Automated Incident Response

This module demonstrates the implementation of a modern Security Operations Center (SOC) architecture by deploying Microsoft Sentinel as a central SIEM and configuring Security Orchestration, Automation, and Response (SOAR). The objective is to establish an automated threat detection and containment pipeline that identifies brute-force attacks and instantly disables the compromised identity in Microsoft Entra ID (Azure AD) without human intervention.

*(Note to recruiters: This project directly reflects the architectural principles tested in the **SC-100 (Cybersecurity Architect)** and **AZ-305** certifications, specifically focusing on Zero Trust ("Assume Breach"), reducing Mean Time to Respond (MTTR), and securely handling system identities via Infrastructure as Code.)*

---

## 🎯 Demonstrated Skills for Recruiters

* **Threat Detection Engineering:** Writing custom Kusto Query Language (KQL) scheduled analytics rules to detect anomalies, such as identifying users with over 10 failed sign-in attempts.


* **Automated Remediation (SOAR):** Orchestrating an Azure Logic App playbook that automatically parses incident data and disables compromised user accounts via the Entra ID API.


* **Advanced IAM & RBAC:** Querying the hidden "Azure Security Insights" service principal and dynamically assigning the "Microsoft Sentinel Automation Contributor" role to allow Sentinel to execute playbooks securely.


* **IaC Problem Solving:** Utilizing native ARM Template deployments within Terraform (`azurerm_resource_group_template_deployment`) to bypass Terraform's native string-handling limitations for nested JSON API connections.



---

## 🏗️ Infrastructure Architecture

This module deploys the following structure:

```text
                                   [ Microsoft Entra ID / Azure AD ]
                                                  ▲ (API Connection: Disable User)
                                                  │
                        ┌─────────────────────────┴─────────────────────────┐
                        │                    Azure Logic App                │
                        │              (Automated Playbook Execution)       │
                        └─────────────────────────▲─────────────────────────┘
                                                  │ (Triggers on Incident)
                        ┌─────────────────────────┴─────────────────────────┐
                        │                   Microsoft Sentinel              │
                        │               (SIEM & Automation Rules)           │
                        └─────────────────────────▲─────────────────────────┘
                                                  │ (Continuous KQL Query)
                        ┌─────────────────────────┴─────────────────────────┐
                        │                Log Analytics Workspace            │
                        │                  (Security Log Data)              │
                        └───────────────────────────────────────────────────┘

```

## 🔒 Enforced Security Controls

* **Automated Threat Containment:** The architecture executes a Logic App playbook (`playbook.json`) that iterates through compromised accounts and patches the `accountEnabled` attribute to `false`.


* **Strict Alert Thresholds:** The Sentinel scheduled alert rule evaluates `SigninLogs` hourly and strictly triggers an incident only if a `UserPrincipalName` accumulates more than 10 failed attempts (`ResultType != "0"`).


* **Least Privilege Playbook Execution:** Microsoft Sentinel is explicitly granted the `Microsoft Sentinel Automation Contributor` role exclusively scoped to the `sentinel-soc-prod-rg` resource group, preventing over-privileged lateral movement.


* **Secure State Management:** The Terraform deployment state is securely managed in a remote Azure backend storage account (`tfstatesec61bb283b`) within the `tfstate` container.



## 📂 Module Files

| File | Description |
| --- | --- |
| `connections.tf` | Creates the explicit API connection resources for Microsoft Sentinel and Azure AD to authorize Logic App actions. |
| `main.tf` | Provisions the foundational Resource Group and the Log Analytics Workspace utilizing the `PerGB2018` SKU with a 30-day retention policy. |
| `playbook.json` | Contains the visual JSON workflow definition for the Logic App, detailing the webhook trigger, entity extraction, and the Entra ID user-disabling loop. |
| `playbook.tf` | Deploys the Logic App via an Incremental ARM Template, assigns RBAC permissions to the Sentinel Service Principal, and creates the Automation Rule linking the KQL alert to the playbook. |
| `providers.tf` | Configures the `azurerm` and `azuread` providers (versions `~> 4.0` and `~> 2.0` respectively) and establishes the remote backend. |
| `sentinel.tf` | Onboards Sentinel to the Log Analytics Workspace and deploys the high-severity KQL scheduled analytics rule to detect brute-force attacks. |

## 🛑 Workload Validation

To definitively prove that the SIEM and SOAR architecture operate correctly:

1. **Oauth API Authorization:** Post-deployment, navigate to the Azure Portal and manually authorize the `sentinel-connection` and `azuread-connection` API connections. *(Note: Azure requires a manual, one-time OAuth consent for Logic App API connections deployed via IaC).*


2. **Trigger the Incident:** Simulate a brute force attack in Entra ID by failing to log into a test account more than 10 times within a one-hour window.


3. **Automated Response:** Sentinel will detect the anomaly, group it into a high-severity incident, and trigger the Automation Rule named "Automated IP blocking remediation" (configured to trigger when the incident title contains "Detect Multiple Failed Sign-ins").


4. **Containment:** The Logic App will execute, extract the user entity, and disable the Entra ID account, stopping the simulated attack in its tracks.



## 🏃 Execution & Deployment Response

When executing `terraform apply`, Terraform uses complex dependency mapping (`depends_on`) to prevent race conditions. It first ensures the Log Analytics Workspace is fully onboarded to Sentinel before deploying the KQL alert rule. Furthermore, it waits for both the ARM template deployment and the `azurerm_role_assignment` to successfully apply before attaching the automation rule to the playbook. This guarantees that Sentinel has the required RBAC permissions to execute the Logic App exactly when the incident is created.
