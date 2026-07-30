.PHONY: help init validate fmt plan apply destroy clean

# Répertoire contenant le code Terraform
DIR = envs/dev-aws

help: ## Affiche l'aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialise Terraform (télécharge les providers)
	terraform -chdir=$(DIR) init

validate: ## Valide la syntaxe des fichiers Terraform
	terraform -chdir=$(DIR) validate

fmt: ## Formate le code Terraform
	terraform -chdir=$(DIR) fmt -recursive

plan: ## Génère et affiche le plan d'exécution
	terraform -chdir=$(DIR) plan -out=tfplan

apply: ## Applique les changements (déploiement)
	terraform -chdir=$(DIR) apply tfplan

apply-auto: ## Applique les changements automatiquement (sans confirmation)
	terraform -chdir=$(DIR) apply -auto-approve

destroy: ## Détruit toute l'infrastructure
	terraform -chdir=$(DIR) destroy

clean: ## Supprime les fichiers locaux générés par Terraform
	rm -rf $(DIR)/.terraform
	rm -f $(DIR)/.terraform.lock.hcl
	rm -f $(DIR)/terraform.tfstate
	rm -f $(DIR)/terraform.tfstate.backup
	rm -f $(DIR)/tfplan
