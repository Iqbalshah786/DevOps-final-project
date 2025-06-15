variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  type        = string
  default     = "devops-project"
}

variable "location" {
  description = "The Azure Region in which all resources should be created"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "devops-project-rg"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "/var/jenkins_home/.ssh/id_rsa.pub"
}
