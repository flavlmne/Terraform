# =============================================================================
# TP3 — Déploiement AWS sécurisé : VPC + Subnet + SG + EC2 nginx
# =============================================================================

# ──────────────────────────────────────────────────────────── Provider ─────
provider "aws" {
  region = var.region

  default_tags {
    tags = local.etiquettes
  }
}

# ──────────────────────────────────────────────────────────── Locals ───────
locals {
  prefixe = "${var.project}-${var.environment}"

  etiquettes = {
    Projet      = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

# =============================================================================
#                                  RÉSEAU
# =============================================================================

# ──────────────────────────────────────────────────────────── VPC ──────────
resource "aws_vpc" "principal" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.prefixe}-vpc" }
}

# ──────────────────────────────────────────────────── Internet Gateway ─────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.principal.id

  tags = { Name = "${local.prefixe}-igw" }
}

# ────────────────────────────────────────────────── Sous-réseau public ─────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${local.prefixe}-public-a" }
}

# ────────────────────────────────────────────────── Table de routage ───────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${local.prefixe}-rt-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
#                           GROUPE DE SÉCURITÉ
# =============================================================================

resource "aws_security_group" "web" {
  name        = "${local.prefixe}-web"
  description = "HTTP public, SSH restreint a IP admin"
  vpc_id      = aws_vpc.principal.id

  # ── HTTP depuis Internet ──────────────────────────────────────────────────
  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── SSH depuis l'IP d'administration UNIQUEMENT ───────────────────────────
  ingress {
    description = "SSH depuis IP admin UNIQUEMENT"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_admin] # ex. "203.0.113.45/32"
  }

  # ── Sortie libre (mises à jour) ──────────────────────────────────────────
  egress {
    description = "Sortie libre (mises a jour)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefixe}-sg-web" }
}

# =============================================================================
#                                INSTANCE EC2
# =============================================================================

# ────────────────────────────────────────────── AMI Ubuntu 24.04 LTS ──────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# ────────────────────────────────────────────── Instance web nginx ─────────
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.ssh_key_name

  # ── Durcissement obligatoire ──────────────────────────────────────────────
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 imposé
    http_put_response_hop_limit = 2          # 2 si conteneurs, 1 sinon
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 10
  }

  # ── User data : installation nginx ────────────────────────────────────────
  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    apt-get install -y nginx
    echo "<h1>${local.prefixe} — deploye par Terraform</h1>" > /var/www/html/index.html
    systemctl enable --now nginx
  EOT

  tags = { Name = "${local.prefixe}-web" }
}
