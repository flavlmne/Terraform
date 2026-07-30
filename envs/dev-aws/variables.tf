# ──────────────────────────────────────────────────────────────── Projet ─────
variable "projet" {
  description = "Nom du projet, utilisé comme préfixe de nommage."
  type        = string
}

variable "environnement" {
  description = "Nom de l'environnement cible (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environnement)
    error_message = "environnement doit valoir dev, staging ou prod."
  }
}

variable "proprietaire" {
  description = "Nom du propriétaire des ressources (étiquetage)."
  type        = string
}

# ──────────────────────────────────────────────────────────────── Réseau ─────
variable "region" {
  description = "Région AWS pour le déploiement."
  type        = string
  default     = "us-east-1"
}

variable "cidr_admin" {
  description = "CIDR autorisé pour l'accès SSH (ex. \"203.0.113.45/32\")."
  type        = string
}

# ──────────────────────────────────────────────────────────── Instances ─────
variable "nom_cle_ssh" {
  description = "Nom de la paire de clés SSH AWS (vockey pour Learner Lab)."
  type        = string
  default     = "vockey"
}

variable "instance_type" {
  description = "Type d'instance EC2."
  type        = string
  default     = "t2.micro"
}
