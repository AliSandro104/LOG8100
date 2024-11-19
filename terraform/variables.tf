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