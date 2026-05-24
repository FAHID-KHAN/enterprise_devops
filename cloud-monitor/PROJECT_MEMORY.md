# Project Memory: Cloud Infrastructure Monitor

This document captures the current state of the Cloud Infrastructure Monitor project, what has been built, why each part exists, and what was learned during setup.

It is written as a memory and learning note, not as a polished public README.

## Project Goal

The goal of this project is to build a cloud infrastructure monitoring tool.

In simple terms:

```text
Create real Azure resources
Collect metrics from those resources
Store the metric history
Show the health/status in an app
Trigger alerts when something looks wrong
```

The project is useful for a cloud developer portfolio because it combines:

- Azure
- Terraform
- Linux
- Networking
- SSH
- Monitoring
- Python backend development
- Alerting
- Documentation

## Current Status

The first stage is complete: Azure demo infrastructure has been created with Terraform.

The project currently includes:

- Terraform infrastructure code
- Azure resource group
- Azure virtual network
- Subnet
- Network security group
- Public IP
- Network interface
- Linux virtual machine
- Storage account
- Blob container
- Log Analytics workspace
- Diagnostic setting for storage metrics
- VM cloud-init bootstrap script
- README documentation

The next stage is to build the Python monitoring application that reads metrics from Azure.

## Folder Structure

```text
cloud-monitor/
├── README.md
├── PROJECT_MEMORY.md
└── infra/
    ├── main.tf
    ├── network.tf
    ├── storage.tf
    ├── vm.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    ├── .gitignore
    └── templates/
        └── cloud-init.yaml
```

## Architecture

The architecture is divided into layers:

```text
Azure Subscription
└── Resource Group
    ├── Network Layer
    │   ├── Virtual Network
    │   ├── Subnet
    │   ├── Network Security Group
    │   ├── Public IP
    │   └── Network Interface
    │
    ├── Compute Layer
    │   └── Linux Virtual Machine
    │
    ├── Storage Layer
    │   ├── Storage Account
    │   └── Blob Container
    │
    └── Monitoring Layer
        ├── Log Analytics Workspace
        └── Diagnostic Settings
```

## Azure Subscription

An Azure subscription is the billing and resource boundary.

Simple meaning:

```text
It is the Azure account area where resources are created and charged.
```

Terraform creates resources inside the active subscription selected by Azure CLI.

The command used to log in:

```bash
az login
```

The command used to confirm the selected subscription:

```bash
az account show --output table
```

## Terraform

Terraform is the Infrastructure as Code tool used in this project.

Simple meaning:

```text
Instead of clicking around in Azure Portal, resources are described in .tf files.
Terraform reads those files and creates the matching cloud infrastructure.
```

The main Terraform commands are:

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## What `terraform init` Did

`terraform init` prepared the Terraform project.

It downloaded provider plugins:

- `azurerm`: lets Terraform create Azure resources
- `random`: lets Terraform create random values, used for unique resource names

Simple meaning:

```text
Terraform learned how to talk to Azure.
```

## What `terraform plan` Did

`terraform plan` previewed the changes before creating anything.

Simple meaning:

```text
Terraform compared the code with Azure and showed what it wanted to create.
```

This helped catch problems before deployment, including:

- Missing SSH key file
- Unsupported SSH key type
- VM SKU capacity issues
- VM family quota issues

## What `terraform apply` Did

`terraform apply` created the Azure resources.

Simple meaning:

```text
Terraform sent requests to Azure and built the infrastructure from the .tf files.
```

After approval with:

```text
yes
```

Terraform created the resources and printed output values such as:

- Resource group name
- VM name
- VM public IP
- Storage account name
- Storage container name
- Log Analytics workspace ID

Do not put real output values in public documentation because they are environment-specific.

## Resource Group

The resource group is created in `main.tf`.

Simple meaning:

```text
A folder in Azure that keeps all project resources together.
```

Why it matters:

- Makes the project easier to manage
- Makes cleanup easier
- Keeps demo resources separate from other Azure resources

## Tags

Tags are key/value labels added to Azure resources.

Example:

```text
project = cloud-monitor
environment = demo
purpose = cloud-monitor-demo
owner = portfolio
```

Simple meaning:

```text
Tags help organize resources and track costs.
```

The tracked example uses a generic owner value so personal information is not pushed.

## Virtual Network

The virtual network is created in `network.tf`.

Simple meaning:

```text
A private network inside Azure.
```

The VM is placed inside this network.

Why it matters:

- Gives the VM private networking
- Lets Azure resources communicate in a controlled way
- Represents real cloud networking knowledge

## Subnet

The subnet is also created in `network.tf`.

Simple meaning:

```text
A smaller section inside the virtual network.
```

The VM network interface is attached to this subnet.

## Public IP

The public IP is created in `network.tf`.

Simple meaning:

```text
The internet address used to reach the VM from your laptop.
```

It is needed so SSH can connect to the VM.

In public docs, use placeholders:

```text
<vm_public_ip>
```

Do not commit a real public IP.

## Network Security Group

The network security group, or NSG, is the Azure firewall.

Simple meaning:

```text
It controls which network traffic is allowed to reach the VM.
```

For this project, it allows SSH:

```text
Port 22
Protocol TCP
Source: the operator's public IP with /32
```

The variable is:

```hcl
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
```

`/32` means only that exact IP address.

This is safer than allowing:

```hcl
allowed_ssh_cidr = "0.0.0.0/0"
```

because `0.0.0.0/0` means the whole internet.

## Network Interface

The network interface, or NIC, is created in `network.tf`.

Simple meaning:

```text
The VM's network card.
```

It connects the VM to:

- Subnet
- Public IP
- Network security group

## Linux Virtual Machine

The VM is created in `vm.tf`.

Simple meaning:

```text
A Linux server running in Azure.
```

This VM is the main resource that the monitor app will observe.

The monitor app can later collect:

- Power state
- CPU usage
- Disk IO
- Network metrics
- Health signals

## SSH

SSH is the secure login method for Linux servers.

Simple meaning:

```text
SSH lets your laptop open a terminal session inside the Azure VM.
```

The login format is:

```bash
ssh azureuser@<vm_public_ip>
```

The VM does not use password login. It uses SSH keys.

## SSH Key Issue

The local machine had an `ed25519` key, but Azure rejected it for this VM setup.

The working solution was to use an RSA key:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

Terraform reads the public key from:

```hcl
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

Simple meaning:

```text
Terraform puts the public key on the VM, and the private key stays on the laptop.
```

Do not commit private keys.

## VM Size And Quota Issue

The first VM size was:

```hcl
vm_size = "Standard_B1s"
```

Azure rejected it because it was not available for the subscription in the selected region.

Another B-series v2 size was tried, but the subscription had `0` quota for that VM family.

The quota was checked with:

```bash
az vm list-usage --location westeurope --output table
```

The working VM size was:

```hcl
vm_size = "Standard_D2s_v3"
```

Simple meaning:

```text
Azure only lets each subscription use certain numbers of vCPUs per VM family.
The selected VM size must fit both regional availability and subscription quota.
```

## Storage Account

The storage account is created in `storage.tf`.

Simple meaning:

```text
Azure cloud storage for files and blobs.
```

Why it exists in this project:

- Gives the monitor another resource to observe
- Provides storage availability and transaction metrics
- Makes the demo infrastructure more realistic

## Blob Container

The blob container is created inside the storage account.

Simple meaning:

```text
A folder-like container for objects/files inside Azure Storage.
```

It is private by default.

## Random Suffix

Storage account names in Azure must be globally unique.

The Terraform `random_string` resource creates a random suffix for the storage account name.

Simple meaning:

```text
Terraform adds random characters so the storage account name does not collide with someone else's.
```

Do not hardcode personal or globally unique resource names in examples.

## Log Analytics Workspace

The Log Analytics workspace is created in `storage.tf`.

Simple meaning:

```text
A place where Azure can store logs and monitoring data.
```

Why it matters:

- Supports realistic monitoring architecture
- Can receive diagnostic data
- Can later be queried by monitoring tools

## Diagnostic Settings

The diagnostic setting sends selected storage metrics to Log Analytics.

Simple meaning:

```text
It tells Azure where to send monitoring data for a resource.
```

In this project, the storage account sends transaction metrics to the Log Analytics workspace.

## Cloud-Init

Cloud-init is configured in:

```text
infra/templates/cloud-init.yaml
```

Simple meaning:

```text
A startup script that runs when the VM is first created.
```

It installs useful packages:

- `stress-ng`
- `sysstat`
- `curl`
- `jq`

It also creates:

```bash
/usr/local/bin/demo-load.sh
```

## Demo Load Script

The VM includes a script:

```bash
sudo demo-load.sh 300s
```

Simple meaning:

```text
It makes the VM work for 5 minutes so Azure Monitor has visible CPU, memory, and disk activity.
```

This is useful because a monitoring dashboard looks empty if the VM is idle.

## Terraform Variables

Variables are defined in:

```text
infra/variables.tf
```

Simple meaning:

```text
Variables are settings that can change without rewriting all the Terraform code.
```

Important variables:

- `project_name`
- `environment`
- `location`
- `owner`
- `admin_username`
- `ssh_public_key_path`
- `allowed_ssh_cidr`
- `vm_size`

## `terraform.tfvars`

`terraform.tfvars` contains local values for the variables.

Simple meaning:

```text
It is the local configuration file for this specific deployment.
```

It can contain:

- Real public IP address
- Local SSH key path
- Region choice
- VM size choice

This file should not be committed.

## `terraform.tfvars.example`

This is the safe example version of `terraform.tfvars`.

Simple meaning:

```text
It shows other people what values they need without exposing real personal values.
```

This file is safe to commit.

## Terraform State

Terraform state files track the real infrastructure Terraform manages.

Examples:

```text
terraform.tfstate
terraform.tfstate.backup
```

Simple meaning:

```text
Terraform state remembers which Azure resources belong to this code.
```

State can contain sensitive or environment-specific information, so it should not be committed for this portfolio project.

The `.gitignore` in `infra/` excludes:

- `.terraform/`
- `terraform.tfvars`
- `terraform.tfstate`
- `terraform.tfstate.backup`
- crash logs

## Current Security Choices

The project uses:

- SSH keys instead of passwords
- Restricted SSH access using `allowed_ssh_cidr`
- Private blob container
- Ignored local Terraform state
- Generic README examples
- Generic owner tag in tracked files

The project avoids committing:

- Real subscription IDs
- Real public IPs
- Real storage account names
- Local Terraform state
- Local `terraform.tfvars`
- Private SSH keys

## Useful Commands

Check Azure login:

```bash
az account show --output table
```

Check Azure VM quota:

```bash
az vm list-usage --location westeurope --output table
```

Check available VM SKUs:

```bash
az vm list-skus --location westeurope --size Standard_D --all --output table
```

Initialize Terraform:

```bash
terraform init
```

Preview Terraform changes:

```bash
terraform plan
```

Create or update infrastructure:

```bash
terraform apply
```

Destroy infrastructure:

```bash
terraform destroy
```

SSH into the VM:

```bash
ssh azureuser@<vm_public_ip>
```

Generate load:

```bash
sudo demo-load.sh 300s
```

## Next Steps

The next stage is the monitoring application.

Recommended MVP:

```text
cloud-monitor/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── azure_client.py
│   ├── collector.py
│   ├── database.py
│   └── alerts.py
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

The app should provide:

- `GET /health`
- `GET /api/resources`
- `GET /api/metrics/latest`
- `GET /api/metrics/history`
- `GET /api/alerts`
- `POST /api/collect`

The app should use:

- FastAPI
- Azure SDK for Python
- SQLite
- Simple alert rules

## Final Project Story

The finished portfolio story should be:

```text
I built a cloud infrastructure monitor on Azure.
Terraform provisions the demo infrastructure.
A Python service collects Azure resource metrics.
The app stores metric history and exposes API endpoints.
Alert rules detect unhealthy states such as high CPU or missing metrics.
The project is documented with setup, architecture, security, and teardown steps.
```

