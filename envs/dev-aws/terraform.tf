terraform {
  required_version = ">= 1.2"

  # Backend S3 pour stocker l'état Terraform à distance (CI/CD)
  # ⚠️ REMPLACE 'mon-bucket-tfstate-maboule' par le vrai nom de ton bucket S3 !
  backend "s3" {
    bucket       = "mon-bucket-tfstate-maboule"
    key          = "maboule/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}
