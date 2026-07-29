# TP 2 — Déploiement multi-cloud sécurisé

Ce dossier contient le rendu complet et reproductible du TP Terraform :

- une racine AWS dans `envs/dev-aws` ;
- une racine Azure dans `envs/dev-azure` ;
- des backends distants chiffrés et versionnés ;
- un serveur nginx avec SSH restreint, authentification par clé et disques chiffrés ;
- les contrôles `pre-commit`, Gitleaks et Trivy ;
- le rapport dans `docs/tp2-rapport.md`.

## Prérequis

- Git, GNU Make, Terraform >= 1.11, pre-commit, Gitleaks et Trivy ;
- AWS CLI authentifié pour AWS ;
- Azure CLI authentifié pour Azure ;
- une clé SSH publique ;
- votre adresse IPv4 publique au format CIDR `/32`.

## Démarrage

```bash
make help
make fmt
make validate
make trivy
```

## État distant

Les scripts `scripts/bootstrap-aws-backend.sh` et
`scripts/bootstrap-azure-backend.sh` créent les stockages d'état. Ils ne
contiennent aucun identifiant et lisent leur configuration depuis des variables
d'environnement.

Après création du stockage, copiez puis adaptez le fichier de configuration :

```bash
cp envs/dev-aws/backend.hcl.example envs/dev-aws/backend.hcl
cp envs/dev-azure/backend.hcl.example envs/dev-azure/backend.hcl
```

Les fichiers `backend.hcl`, `terraform.tfvars`, `.terraform/`, les états et les
plans sont ignorés. Les fichiers `.terraform.lock.hcl` sont, eux, versionnés.

## Déploiement

Créez localement un `terraform.tfvars` à partir de l'exemple de chaque cloud,
puis exécutez :

```bash
make init-aws
make plan-aws
terraform -chdir=envs/dev-aws apply dev.tfplan

make init-azure
make plan-azure
terraform -chdir=envs/dev-azure apply dev.tfplan
```

Relisez toujours le plan avant `apply`. À la fin du TP :

```bash
make destroy-aws
make destroy-azure
```
