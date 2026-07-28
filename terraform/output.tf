output "instance_public_ip" {
  value = aws_instance.flav_webserver.public_ip
}
