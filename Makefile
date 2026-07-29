# ============= REPRODUCTIBILITY AND HARDENING =========================================
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
# ============ COLOR ANSI ==============================
INFO_COLOR := \033[36;1m
WARNING_COLOR := \033[33;1m
ERROR_COLOR := \033[31;1m
RESET_COLOR := \033[0m
# ====================================================
GIT_DIR := scripts/git
ANSIBLE_DIR := ansible
TF_DIR := terraform
TF_CHG_DIR := terraform -chdir=$(TF_DIR)
# =====================================================

.PHONY: help terraform git lint secrets clean ansible.play tf.init tf.plan tf.build tf.check tf.pipe
.DEFAULT_GOAL := help

help: ## shows this help
	@grep -E "^[a-z0-9A-Z._-]+:.*?## .*$$" $(MAKEFILE_LIST) |\
	 sort | awk 'BEGIN {FS=":.*?##"} {printf "$(INFO_COLOR)%-20s$(RESET_COLOR)%s\n", $$1, $$2}'

lint: ## runs pre-commit linters
	@pre-commit run --all-files

secrets: ## detects secrets with gitleaks
	@gitleaks detect --source . --verbose

clean: ## cleans temporary and build files
	@rm -rf .terraform *.tfstate *.tfstate.* *.log

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

tf.check: ## verifies Terraform formatting and configuration without cloud credentials
	@terraform -chdir=$(TF_DIR) fmt -check -recursive
	@terraform -chdir=$(TF_DIR) init -backend=false -input=false
	@terraform -chdir=$(TF_DIR) validate -no-color

tf.build: ## terraform build
	@terraform -chdir=$(TF_DIR) apply -auto-approve

tf.normalize:
	$(TF_CHG_DIR) fmt
	tflint --chdir=$(TF_DIR)
	echo -e "${INFO_COLOR}Terraform files normalized${RESET_COLOR}"

tf.pipe:
	@$(TF_CHG_DIR) validate
	@$(TF_CHG_DIR) plan --out tfplan
	@$(TF_CHG_DIR) show -json tfplan > $(TF_DIR)/tfplan.json
	trivy config $(TF_DIR)/tfplan.json
	echo -e "${INFO_COLOR}Terraform pipe complete${RESET_COLOR}"

tf.apply:
	@$(TF_CHG_DIR) apply --auto-approve
	echo -e "${INFO_COLOR}Terraform apply complete${RESET_COLOR}"
