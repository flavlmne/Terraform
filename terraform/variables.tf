variable "aws_default_region" {
  type        = string
  default     = "us-east-1"
  description = "Région AWS pour le déploiement"
}

variable "default_ubuntu_ami" {
  type        = string
  default     = "ami-0446f93cefa2981e5"
  description = "AMI Ubuntu 22.04 LTS"
}

variable "default_vpc_id" {
  type        = string
  default     = "vpc-0d52b82865c0ed086"
  description = "ID du VPC AWS par défaut"
}

variable "default_public_subnet_id" {
  type        = string
  default     = "subnet-080466c956ef16d82"
  description = "ID du sous-réseau public"
}

variable "default_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Type d'instance EC2"
}

variable "default_security_group_id" {
  type        = string
  default     = "sg-07f0ad52f78074f02"
  description = "ID du groupe de sécurité AWS"
}

variable "key_name" {
  type        = string
  default     = "vockey"
  description = "Nom de la paire de clés SSH AWS (vockey pour Learner Lab)"
}
