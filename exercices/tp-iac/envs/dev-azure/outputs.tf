output "resource_group_name" {
  description = "Nom du groupe de ressources Azure."
  value       = azurerm_resource_group.principal.name
}

output "url_publique" {
  description = "URL HTTP publique du serveur nginx."
  value       = "http://${azurerm_public_ip.web.ip_address}"
}
