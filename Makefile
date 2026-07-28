
# ============= REPRODUCTIBILITY AND HARDENING =========================================
SHELL := /bin/bash
SHELLFLAGS := -eu -o pipefail -c
# ============ COLOR ANSI ==============================
INFO_COLOR := \033[36;1m
WARNING_COLOR := \033[33;1m
ERROR_COLOR := \033[31;1m
RESET_COLOR := \033[0m
# ====================================================
GIT_DIR := scripts/git
ANSIBLE_DIR := ansible
TF_DIR := terraform
# =====================================================

.PHONY: help terraform git
.DEFAULT_GOAL := help

help: ## shows this help
	@grep -E "^[a-z0-9A-Z._-]+:.*?## .*$$" $(MAKEFILE_LIST) |\
	 sort | awk 'BEGIN {FS=":.*?##"} {printf "$(INFO_COLOR)%-20s$(RESET_COLOR)%s\n", $$1, $$2}'

ansible: ## show ansible version
	@ansible --version 

terraform: ## shows terraform version
	@terraform -v

git: ## initializes git
	@./$(GIT_DIR)/main.sh

ansible.play: ## runs ansible playbook
	@ansible-playbook $(ANSIBLE_DIR)/localhost/playbook.yml

tf.init: ## initializes terraform
	@terraform -chdir=$(TF_DIR) init

tf.plan: ## terraform plan
	@terraform -chdir=$(TF_DIR) plan

tf.build: ## terraform build
	@terraform -chdir=$(TF_DIR) apply -auto-approve