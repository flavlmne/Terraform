SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables --no-print-directory

AWS_DIR := envs/dev-aws
AZURE_DIR := envs/dev-azure

.PHONY: help lint secrets fmt validate trivy \
	init-aws plan-aws destroy-aws \
	init-azure plan-azure destroy-azure clean

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

lint: ## Analyse statique
	pre-commit run --config .pre-commit-config.yaml --all-files

secrets: ## Détection de secrets
	gitleaks detect --source . --verbose

fmt: ## Vérifie le formatage Terraform
	terraform -chdir=$(AWS_DIR) fmt -check -recursive
	terraform -chdir=$(AZURE_DIR) fmt -check -recursive

validate: ## Initialise sans backend et valide AWS et Azure
	terraform -chdir=$(AWS_DIR) init -backend=false -input=false
	terraform -chdir=$(AWS_DIR) validate
	terraform -chdir=$(AZURE_DIR) init -backend=false -input=false
	terraform -chdir=$(AZURE_DIR) validate

trivy: ## Recherche les mauvaises configurations IaC
	trivy config --exit-code 1 --severity HIGH,CRITICAL envs/

init-aws: ## Initialise le backend distant AWS
	terraform -chdir=$(AWS_DIR) init -backend-config=backend.hcl

plan-aws: ## Calcule et enregistre le plan AWS
	terraform -chdir=$(AWS_DIR) plan -out=dev.tfplan

destroy-aws: ## Détruit les ressources AWS
	terraform -chdir=$(AWS_DIR) destroy

init-azure: ## Initialise le backend distant Azure
	terraform -chdir=$(AZURE_DIR) init -backend-config=backend.hcl

plan-azure: ## Calcule et enregistre le plan Azure
	terraform -chdir=$(AZURE_DIR) plan -out=dev.tfplan

destroy-azure: ## Détruit les ressources Azure
	terraform -chdir=$(AZURE_DIR) destroy

clean: ## Nettoie les artefacts locaux
	rm -rf $(AWS_DIR)/.terraform $(AZURE_DIR)/.terraform
	rm -f $(AWS_DIR)/*.tfplan $(AWS_DIR)/*.tfplan.json
	rm -f $(AZURE_DIR)/*.tfplan $(AZURE_DIR)/*.tfplan.json
