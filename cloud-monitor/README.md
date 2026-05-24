# Cloud Infrastructure Monitor

A portfolio project that provisions a small Azure environment with Terraform and uses it as the target infrastructure for a cloud monitoring application.

The goal is to demonstrate practical cloud developer skills: Infrastructure as Code, Azure networking, Linux VM access, storage monitoring, metric collection, and alerting.

## Architecture

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

## What This Project Covers

- Azure infrastructure provisioning with Terraform
- Resource group based environment management
- Linux VM deployment with SSH key authentication
- Azure virtual networking and firewall rules
- Storage account and private blob container setup
- Log Analytics workspace creation
- Diagnostic metric routing
- VM load generation for realistic monitoring data
- Clean teardown using Terraform

## Repository Structure

```text
cloud-monitor/
├── infra/
│   ├── main.tf
│   ├── network.tf
│   ├── storage.tf
│   ├── vm.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── templates/
│       └── cloud-init.yaml
└── README.md
```

## Infrastructure Components

**Resource Group**

A dedicated Azure container for all demo resources. This keeps the project easy to inspect and destroy.

**Virtual Network And Subnet**

A private network where the VM is placed.

**Network Security Group**

Acts as the firewall. The SSH rule should be restricted to the operator's current public IP using CIDR notation.

**Linux Virtual Machine**

The main compute resource being monitored. It is provisioned with cloud-init and includes a small load generation script for demo metrics.

**Storage Account And Blob Container**

Provides a storage resource for monitoring transaction and availability metrics.

**Log Analytics Workspace**

Stores Azure diagnostic data and gives the project a realistic monitoring foundation.

**Diagnostic Settings**

Routes selected storage metrics into Log Analytics.

## Prerequisites

- Azure account with an active subscription
- Azure CLI
- Terraform
- SSH key pair

Check local tools:

```bash
az --version
terraform -version
```

Login to Azure:

```bash
az login
az account show --output table
```

## Configuration

Create a local Terraform variables file:

```bash
cd cloud-monitor/infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` before deployment:

```hcl
location            = "westeurope"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
allowed_ssh_cidr    = "YOUR_PUBLIC_IP/32"
vm_size             = "Standard_D2s_v3"
```

Find the current public IP:

```bash
curl ifconfig.me
```

Use the returned IP with `/32` for `allowed_ssh_cidr`.

Example format:

```hcl
allowed_ssh_cidr = "203.0.113.10/32"
```

Do not commit `terraform.tfvars` because it is machine and environment specific.

## Deploy

From the Terraform directory:

```bash
terraform init
terraform plan
terraform apply
```

Approve the apply when Terraform asks:

```text
yes
```

Terraform prints output values after deployment, including:

```text
resource_group_name
vm_name
vm_public_ip
storage_account_name
storage_container_name
log_analytics_workspace_id
```

## Generate Demo Metrics

SSH into the VM using the public IP from Terraform output:

```bash
ssh azureuser@<vm_public_ip>
```

Run the demo load script:

```bash
sudo demo-load.sh 300s
```

This creates a short CPU, memory, and disk IO burst so the monitoring application has real infrastructure activity to collect.

## Planned Monitor Application

The next stage is a Python service that connects to Azure and collects resource state and metric history.

Target MVP:

- FastAPI backend
- Azure SDK based metric collector
- SQLite database for local metric history
- Resource inventory endpoint
- VM power state endpoint
- CPU and disk metric collection
- Storage availability and transaction metrics
- Simple alert rules
- Dockerfile for local deployment

Example alert rules:

- VM is not running
- CPU above threshold
- Storage availability below threshold
- Metrics have not been collected recently

## Security Notes

- Use SSH keys instead of passwords.
- Restrict SSH access with `allowed_ssh_cidr`.
- Do not commit `terraform.tfvars`.
- Do not commit Terraform state files.
- Do not store subscription IDs, public IPs, access keys, or personal account details in documentation.

## Teardown

Destroy resources when the demo is finished to avoid ongoing cloud costs:

```bash
cd cloud-monitor/infra
terraform destroy
```

Approve the destroy when Terraform asks:

```text
yes
```

