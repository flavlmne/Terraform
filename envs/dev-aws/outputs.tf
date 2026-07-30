# ──────────────────────────────────────────────────────────────── Sorties ────
output "url_publique" {
  description = "URL HTTP du serveur web déployé."
  value       = "http://${aws_instance.web.public_ip}"
}

output "ip_publique" {
  description = "Adresse IP publique de l'instance."
  value       = aws_instance.web.public_ip
}

output "id_instance" {
  description = "Identifiant de l'instance EC2."
  value       = aws_instance.web.id
}

output "id_vpc" {
  description = "Identifiant du VPC créé."
  value       = aws_vpc.principal.id
}

output "id_security_group" {
  description = "Identifiant du groupe de sécurité."
  value       = aws_security_group.web.id
}
