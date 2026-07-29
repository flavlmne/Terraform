SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --warn-undefined-variables --no-print-directory

.PHONY: help hello build clean

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}'

hello: ## Affiche mon nom et le shell user
	@echo "Flavien - Utilisateur: $$USER"

build: ## Crée un dossier out/ et y écrit la date
	mkdir -p out/
	date > out/version.txt

clean: ## Supprime le dossier out/
	rm -rf out/
