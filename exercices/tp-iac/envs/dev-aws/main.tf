locals {
  prefixe = "${var.projet}-${var.environnement}"
  etiquettes = {
    Projet      = var.projet
    Environment = var.environnement
    ManagedBy   = "terraform"
    Owner       = var.proprietaire
  }
}

resource "aws_vpc" "principal" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefixe}-vpc"
  }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefixe}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefixe}-public-a"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = {
    Name = "${local.prefixe}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Le TP impose un serveur public qui installe nginx au démarrage. Les sorties
# HTTP/HTTPS sont donc autorisées, mais aucun autre port n'est ouvert.
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "web" {
  name        = "${local.prefixe}-web"
  description = "HTTP public et SSH restreint a l'adresse de l'administrateur"
  vpc_id      = aws_vpc.principal.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH depuis l'adresse d'administration uniquement"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_admin]
  }

  egress {
    description = "HTTP sortant pour les mises a jour"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS sortant pour les mises a jour"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefixe}-sg-web"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.nom_cle_ssh
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update
    apt-get install -y nginx
    printf '%s\n' '<h1>${local.prefixe} — déployé par Terraform sur AWS</h1>' > /var/www/html/index.html
    systemctl enable --now nginx
  EOT

  tags = {
    Name = "${local.prefixe}-web"
  }
}
