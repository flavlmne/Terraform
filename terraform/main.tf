provider "aws" {
  region = var.aws_default_region
}

resource "aws_instance" "flav_webserver" {
  ami                    = var.default_ubuntu_ami
  subnet_id              = var.default_public_subnet_id
  instance_type          = var.default_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.default_security_group_id]
}
