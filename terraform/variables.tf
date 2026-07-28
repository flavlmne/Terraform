
variable "aws_default_region" {
  default     = "us-east-1"
  description = "My AWS region"
}

variable "default_ubuntu_ami" {
  default     = "ami-0446f93cefa2981e5"
  type        = string
  description = "Default Ubuntu AMI"
}

variable "default_vpc_id" {
  default = "vpc-0d52b82865c0ed086"
  type    = string
}

variable "default_public_subnet_id" {
  default = "subnet-080466c956ef16d82"
  type    = string
}

variable "default_instance_type" {
  default = "t2.micro"
}

variable "default_security_group_id" {
  default = "sg-07f0ad52f78074f02"
  type    = string
}

variable "key_name" {
  default     = "vockey"
  type        = string
  description = "Pre-existing AWS Key Pair name (vockey for Learner Lab)"
}
