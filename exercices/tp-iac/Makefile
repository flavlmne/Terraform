SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables --no-print-directory

.PHONY: help lint secrets clean

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}'

lint: ## Analyse statique
	@echo "Linting..."

secrets: ## Détection de secrets
	gitleaks detect --source . --verbose

clean: ## Nettoie les artefacts locaux
	rm -rf out/
