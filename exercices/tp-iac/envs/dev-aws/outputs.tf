output "instance_id" {
  description = "Identifiant de l'instance EC2."
  value       = aws_instance.web.id
}

output "url_publique" {
  description = "URL HTTP publique du serveur nginx."
  value       = "http://${aws_instance.web.public_ip}"
}
