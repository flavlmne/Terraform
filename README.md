# Infrastructure & Configuration Management (TP 1)

Projet de gestion d'infrastructure as code (IaC) utilisant Terraform et Ansible avec intégration de garde-fous de sécurité.

## Prérequis

Avant de commencer, assurez-vous de disposer des outils suivants installés sur votre machine :

- **Git** (>= 2.30)
- **Make**
- **Terraform** (>= 1.2)
- **Ansible** (>= 2.10)
- **AWS CLI** (configuré avec vos accès)
- **pre-commit**
- **gitleaks**
- **git-filter-repo**

## Démarrage

1. **Initialiser le dépôt et les hooks pre-commit** :
   ```bash
   make help
   pre-commit install
   ```

2. **Vérifier l'absence de secrets** :
   ```bash
   make secrets
   ```

3. **Initialiser et appliquer l'infrastructure Terraform** :
   ```bash
   make tf.init
   make tf.plan
   make tf.build
   ```

4. **Exécuter le playbook Ansible** :
   ```bash
   make ansible.play
   ```
