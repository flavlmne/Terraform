variable "aws_default_region" {
  type        = string
  description = "Région AWS pour le déploiement"
}

variable "default_ubuntu_ami" {
  type        = string
  description = "AMI Ubuntu 22.04 LTS"
}

variable "default_public_subnet_id" {
  type        = string
  description = "ID du sous-réseau public"
}

variable "default_instance_type" {
  type        = string
  description = "Type d'instance EC2"
}

variable "default_security_group_id" {
  type        = string
  description = "ID du groupe de sécurité AWS"
}

variable "key_name" {
  type        = string
  description = "Nom de la paire de clés SSH AWS (vockey pour Learner Lab)"
}
