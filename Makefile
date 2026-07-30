.PHONY: help init validate fmt fmt-check plan apply apply-auto destroy destroy-auto output show clean lint sec

# ── Variables ─────────────────────────────────────────────────────────────────
# Répertoire cible (modifiable à la volée : make plan DIR=envs/prod)
DIR ?= envs/dev-aws

# Fichier de plan (localisé dans le répertoire d'exécution)
PLAN_FILE = tfplan

# Couleurs pour le help
CYAN := \033[36m
RESET := \033[0m

# ── Commandes par défaut ──────────────────────────────────────────────────────
help: ## Affiche cette aide avec la liste des commandes disponibles
	@echo "Utilisation: make <commande> [DIR=chemin/vers/env]"
	@echo ""
	@echo "Commandes disponibles :"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-18s$(RESET) %s\n", $$1, $$2}'

# ── Commandes Terraform ───────────────────────────────────────────────────────
init: ## Télécharge les providers et initialise le backend
	@echo "=> Initialisation de Terraform dans $(DIR)..."
	terraform -chdir=$(DIR) init

init-upgrade: ## Met à jour les versions des providers et modules
	@echo "=> Mise à jour des providers Terraform..."
	terraform -chdir=$(DIR) init -upgrade

validate: ## Vérifie la syntaxe et la validité du code HCL
	@echo "=> Validation du code Terraform..."
	terraform -chdir=$(DIR) validate

fmt: ## Formate automatiquement tous les fichiers .tf du projet
	@echo "=> Formatage du code Terraform..."
	terraform -chdir=$(DIR) fmt -recursive

fmt-check: ## Vérifie si le code respecte le formatage (sans le modifier)
	@echo "=> Vérification du formatage..."
	terraform -chdir=$(DIR) fmt -check -recursive

plan: ## Génère un plan d'exécution et le sauvegarde (tfplan)
	@echo "=> Génération du plan Terraform..."
	terraform -chdir=$(DIR) plan -out=$(PLAN_FILE)

apply: ## Applique le plan d'exécution précédemment généré
	@echo "=> Déploiement de l'infrastructure..."
	terraform -chdir=$(DIR) apply $(PLAN_FILE)

apply-auto: ## Applique les changements automatiquement (DANGER : pas de confirmation)
	@echo "=> Déploiement automatique en cours..."
	terraform -chdir=$(DIR) apply -auto-approve

destroy: ## Calcule et demande confirmation pour détruire l'infrastructure
	@echo "=> Demande de destruction de l'infrastructure..."
	terraform -chdir=$(DIR) destroy

destroy-auto: ## Détruit l'infrastructure automatiquement (DANGER : pas de confirmation)
	@echo "=> Destruction automatique en cours..."
	terraform -chdir=$(DIR) destroy -auto-approve

output: ## Affiche les variables de sortie (outputs) de l'état actuel
	@echo "=> Outputs Terraform :"
	terraform -chdir=$(DIR) output

show: ## Affiche l'état complet (tfstate) au format lisible
	terraform -chdir=$(DIR) show

# ── Qualité & Sécurité (Nécessite des outils tiers) ───────────────────────────
lint: ## Analyse le code avec tflint (nécessite tflint installé)
	@echo "=> Initialisation et Analyse avec TFLint..."
	@tflint --init
	@tflint --chdir=$(DIR) && echo "✅ Aucun problème détecté par TFLint !"

sec: ## Analyse la sécurité avec tfsec (nécessite tfsec installé)
	@echo "=> Analyse avec TFSec..."
	@tfsec $(DIR) && echo "✅ Aucun problème de sécurité détecté par TFSec !"

trivy: ## Analyse la sécurité et les vulnérabilités avec Trivy
	@echo "=> Analyse avec Trivy..."
	@trivy config $(DIR)


# ── Nettoyage ─────────────────────────────────────────────────────────────────
clean: ## Supprime le cache local Terraform (.terraform, .tfstate, tfplan)
	@echo "=> Nettoyage des fichiers locaux..."
	rm -rf $(DIR)/.terraform
	rm -f $(DIR)/.terraform.lock.hcl
	rm -f $(DIR)/terraform.tfstate
	rm -f $(DIR)/terraform.tfstate.backup
	rm -f $(DIR)/$(PLAN_FILE)
	@echo "Nettoyage terminé."
