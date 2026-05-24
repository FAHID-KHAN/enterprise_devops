variable "project_name" {
  description = "Short name used in Azure resource names."
  type        = string
  default     = "cloud-monitor"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "demo"
}

variable "location" {
  description = "Azure region for the demo resources."
  type        = string
  default     = "westeurope"
}

variable "owner" {
  description = "Owner tag for cost tracking."
  type        = string
  default     = "portfolio"
}

variable "admin_username" {
  description = "Linux admin username for the demo VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key Terraform should add to the demo VM."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the VM. Replace with your public IP plus /32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_size" {
  description = "VM size for demo metrics. Pick a SKU whose family has available quota in your Azure region."
  type        = string
  default     = "Standard_D2s_v3"
}
