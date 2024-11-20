# variables.tf

variable "admin_username" {
  type        = string
  description = "The admin username for the Virtual Machine."
}

variable "admin_password" {
  description = "The admin password for the Linux VM."
  type        = string
  sensitive   = true
}

variable "iac_remote_repository_url" {
  description = "The remote repository URL containing the IaC scripts."
  type        = string
  sensitive   = true
}