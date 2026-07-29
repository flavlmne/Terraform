variable "cidr_admin" {
  description = "Adresse IPv4 publique autorisée à se connecter en SSH, au format x.x.x.x/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_admin, 0)) && endswith(var.cidr_admin, "/32")
    error_message = "cidr_admin doit être une adresse IPv4 unique au format x.x.x.x/32."
  }
}

variable "environnement" {
  description = "Nom de l'environnement."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environnement)
    error_message = "environnement doit valoir dev, staging ou prod."
  }
}

variable "nom_cle_ssh" {
  description = "Nom d'une paire de clés EC2 existante."
  type        = string
}

variable "projet" {
  description = "Nom court du projet."
  type        = string
  default     = "tp-iac"
}

variable "proprietaire" {
  description = "Propriétaire des ressources cloud."
  type        = string
}

variable "region" {
  description = "Région AWS cible."
  type        = string
  default     = "eu-west-3"
}
