# outputs.tf

output "public_ip_address" {
  value       = azurerm_public_ip.public_ip.ip_address
}

output "dns" {
  value = azurerm_public_ip.public_ip.fqdn
  description = "The fully qualified domain name of the public IP."
}