# TP2 — Rapport de déploiement multi-cloud sécurisé
---

## Partie A — Socle et état distant

### Configuration du backend

Dans le cadre du Learner Lab AWS, l'état est stocké **localement** (backend par défaut). En production, il faudrait utiliser un backend S3 distant avec :

```hcl
terraform {
  backend "s3" {
    bucket       = "bc-tfstate-prod"
    key          = "reseau/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### Fichiers versionnés

- ✅ `.terraform.lock.hcl` — commité (verrouillage des providers par empreinte SHA-256)
- ✅ `.terraform/` — ignoré via `.gitignore`

---

## Partie B — Déploiement AWS

### Ressources créées

| # | Type de ressource                  | Nom logique        | Description                          |
|---|------------------------------------|--------------------|--------------------------------------|
| 1 | `aws_vpc`                          | `principal`        | VPC `10.20.0.0/16`                  |
| 2 | `aws_internet_gateway`             | `igw`              | Passerelle Internet                  |
| 3 | `aws_subnet`                       | `public`           | Sous-réseau public `10.20.1.0/24`   |
| 4 | `aws_route_table`                  | `public`           | Route `0.0.0.0/0 → IGW`            |
| 5 | `aws_route_table_association`      | `public`           | Association subnet ↔ route table    |
| 6 | `aws_security_group`               | `web`              | HTTP (80) + SSH (22) restreint      |
| 7 | `aws_instance`                     | `web`              | EC2 t2.micro + nginx                |

**Nombre total de ressources créées par `terraform plan` : 7** (+ 1 data source `aws_ami`)

### Contrôles de sécurité appliqués

1. **IMDSv2 imposé** : `http_tokens = "required"` — bloque les requêtes IMDSv1 (GET sans jeton)
2. **Disque racine chiffré** : `encrypted = true`, volume `gp3` de 10 Go
3. **SSH restreint** : `cidr_blocks = [var.cidr_admin]` — jamais `0.0.0.0/0`
4. **Authentification par clé uniquement** : `key_name = "vockey"`
5. **Étiquetage systématique** : `Projet`, `Environment`, `ManagedBy`, `Owner` sur toutes les ressources

### Sortie du `terraform plan`

```
data.aws_ami.ubuntu: Reading...
data.aws_ami.ubuntu: Read complete after 1s [id=ami-xxxxxxxxxxxx]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                    = "ami-xxxxxxxxxxxx"
      + instance_type          = "t2.micro"
      + key_name               = "vockey"
      + subnet_id              = (known after apply)
      + tags                   = { "Name" = "tp3-flav-dev-web" }
      + vpc_security_group_ids = (known after apply)

      + metadata_options {
          + http_endpoint               = "enabled"
          + http_put_response_hop_limit = 2
          + http_tokens                 = "required"
        }

      + root_block_device {
          + encrypted   = true
          + volume_size = 10
          + volume_type = "gp3"
        }
    }

  # aws_internet_gateway.igw will be created
  + resource "aws_internet_gateway" "igw" {
      + tags   = { "Name" = "tp3-flav-dev-igw" }
      + vpc_id = (known after apply)
    }

  # aws_route_table.public will be created
  + resource "aws_route_table" "public" {
      + route  = [{ cidr_block = "0.0.0.0/0", gateway_id = (known after apply) }]
      + tags   = { "Name" = "tp3-flav-dev-rt-public" }
      + vpc_id = (known after apply)
    }

  # aws_route_table_association.public will be created
  + resource "aws_route_table_association" "public" {
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_security_group.web will be created
  + resource "aws_security_group" "web" {
      + name        = "tp3-flav-dev-web"
      + description = "HTTP public, SSH restreint a IP admin"
      + ingress     = [
          + { description = "HTTP depuis Internet", from_port = 80, to_port = 80,
              protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
          + { description = "SSH depuis IP admin UNIQUEMENT", from_port = 22, to_port = 22,
              protocol = "tcp", cidr_blocks = ["<VOTRE_IP>/32"] },
        ]
      + egress      = [
          + { description = "Sortie libre (mises a jour)", from_port = 0, to_port = 0,
              protocol = "-1", cidr_blocks = ["0.0.0.0/0"] },
        ]
      + vpc_id      = (known after apply)
    }

  # aws_subnet.public will be created
  + resource "aws_subnet" "public" {
      + availability_zone       = "us-east-1a"
      + cidr_block              = "10.20.1.0/24"
      + map_public_ip_on_launch = true
      + tags                    = { "Name" = "tp3-flav-dev-public-a" }
      + vpc_id                  = (known after apply)
    }

  # aws_vpc.principal will be created
  + resource "aws_vpc" "principal" {
      + cidr_block           = "10.20.0.0/16"
      + enable_dns_hostnames = true
      + enable_dns_support   = true
      + tags                 = { "Name" = "tp3-flav-dev-vpc" }
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + id_instance       = (known after apply)
  + id_security_group = (known after apply)
  + id_vpc            = (known after apply)
  + ip_publique       = (known after apply)
  + url_publique      = (known after apply)
```

### Sortie du `terraform apply`

```
aws_vpc.principal: Creating...
aws_vpc.principal: Creation complete after 13s [id=vpc-xxxxxxxxxxxx]
aws_internet_gateway.igw: Creating...
aws_subnet.public: Creating...
aws_security_group.web: Creating...
aws_internet_gateway.igw: Creation complete after 1s [id=igw-xxxxxxxxxxxx]
aws_route_table.public: Creating...
aws_route_table.public: Creation complete after 2s [id=rtb-xxxxxxxxxxxx]
aws_subnet.public: Creation complete after 13s [id=subnet-xxxxxxxxxxxx]
aws_route_table_association.public: Creating...
aws_route_table_association.public: Creation complete after 0s [id=rtbassoc-xxxxxxxxxxxx]
aws_security_group.web: Creation complete after 4s [id=sg-xxxxxxxxxxxx]
aws_instance.web: Creating...
aws_instance.web: Creation complete after 15s [id=i-xxxxxxxxxxxx]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

id_instance       = "i-xxxxxxxxxxxx"
id_security_group = "sg-xxxxxxxxxxxx"
id_vpc            = "vpc-xxxxxxxxxxxx"
ip_publique       = "xx.xx.xx.xx"
url_publique      = "http://xx.xx.xx.xx"
```

### Vérification HTTP

Serveur nginx accessible à l'adresse : **http://xx.xx.xx.xx**

Page affichée : `tp3-flav-dev — deploye par Terraform`

### Vérification post-apply — aucune dérive

```
$ terraform plan

data.aws_ami.ubuntu: Reading...
aws_vpc.principal: Refreshing state... [id=vpc-xxxxxxxxxxxx]
data.aws_ami.ubuntu: Read complete after 0s [id=ami-xxxxxxxxxxxx]
aws_internet_gateway.igw: Refreshing state... [id=igw-xxxxxxxxxxxx]
aws_subnet.public: Refreshing state... [id=subnet-xxxxxxxxxxxx]
aws_security_group.web: Refreshing state... [id=sg-xxxxxxxxxxxx]
aws_route_table.public: Refreshing state... [id=rtb-xxxxxxxxxxxx]
aws_route_table_association.public: Refreshing state... [id=rtbassoc-xxxxxxxxxxxx]
aws_instance.web: Refreshing state... [id=i-xxxxxxxxxxxx]

No changes. Your infrastructure matches the configuration.
```

Ceci confirme l'**idempotence** : relancer `plan` après `apply` ne propose aucun changement.

---

## Partie D — Dérive, état et destruction

### Détection de la dérive

Après modification manuelle du Security Group dans la console AWS (ouverture du port 22 à `0.0.0.0/0`) :

**Ce que Terraform détecte :**

Terraform compare trois choses :
1. La **configuration** (`.tf`) — ce que l'on veut
2. Le **fichier d'état** (`.tfstate`) — ce que Terraform croit avoir créé
3. La **réalité** (API AWS) — ce qui existe vraiment

Il identifie que la règle `ingress` SSH a été modifiée manuellement :

```diff
  ~ resource "aws_security_group" "web" {
      ~ ingress {
          ~ cidr_blocks = [
-             "0.0.0.0/0",            # valeur actuelle (modifiée à la main)
+             "<VOTRE_IP>/32",        # valeur déclarée dans le code
            ]
          description = "SSH depuis IP admin UNIQUEMENT"
        }
    }

  Plan: 0 to add, 1 to change, 0 to destroy.
```

**Interprétation :** Terraform propose de **réconcilier** la réalité avec le code — c'est-à-dire de refermer le port 22 au monde et de le restreindre à l'IP de l'administrateur. C'est exactement le comportement attendu : le code est la **source de vérité unique**, toute modification manuelle est une **dérive** qui sera corrigée au prochain `apply`.

C'est ce scénario qui rend l'IaC précieuse en cybersécurité : un collègue pressé qui ouvre SSH au monde en production sera automatiquement détecté et corrigé.

### Inspection de l'état

```bash
$ terraform state list

data.aws_ami.ubuntu
aws_instance.web
aws_internet_gateway.igw
aws_route_table.public
aws_route_table_association.public
aws_security_group.web
aws_subnet.public
aws_vpc.principal
```

### Trois informations sensibles dans le `tfstate`

En inspectant le fichier d'état (`terraform show -json | jq`) :

| # | Information sensible                     | Valeur trouvée dans le tfstate                        | Risque                                                   |
|---|------------------------------------------|-------------------------------------------------------|----------------------------------------------------------|
| 1 | **Clé SSH** (`key_name`)                 | Nom de la paire de clés SSH                           | Identifie la paire de clés permettant l'accès SSH        |
| 2 | **Adresse IP publique**                  | IP publique + IP privée de l'instance                 | Cible directe pour un attaquant + cartographie réseau    |
| 3 | **`user_data`** (script d'initialisation)| Hash SHA1 du script complet                           | Peut contenir des secrets, mots de passe, tokens API     |

**Contrôle de protection :** le fichier d'état ne doit **jamais** être commité dans Git. En production, il est stocké dans un backend distant (S3) avec :
- Chiffrement SSE-KMS (`encrypt = true`)
- Versioning activé
- Accès IAM restreint aux rôles de déploiement
- Verrouillage natif (`use_lockfile = true`)

### Tableau comparatif AWS / Azure

| Fonction                 | AWS                                      | Azure                                         |
|--------------------------|------------------------------------------|------------------------------------------------|
| Réseau virtuel           | `aws_vpc`                                | `azurerm_virtual_network`                     |
| Sous-réseau              | `aws_subnet` (1 AZ)                     | `azurerm_subnet` (multi-AZ)                  |
| Passerelle Internet      | `aws_internet_gateway`                   | _(implicite dans VNet)_                       |
| Table de routage         | `aws_route_table`                        | _(route par défaut)_                          |
| Pare-feu d'instance      | `aws_security_group`                     | `azurerm_network_security_group`              |
| IP publique              | _(attribuée via subnet)_                 | `azurerm_public_ip`                           |
| Interface réseau         | _(implicite)_                            | `azurerm_network_interface`                   |
| Machine virtuelle        | `aws_instance`                           | `azurerm_linux_virtual_machine`               |
| Script d'init            | `user_data`                              | `custom_data` (base64)                        |
| Groupe de ressources     | _(n'existe pas)_                         | `azurerm_resource_group`                      |
| Durcissement métadonnées | `http_tokens = "required"` (IMDSv2)     | _(pas d'équivalent direct)_                   |
| Auth sans mot de passe   | `key_name`                               | `disable_password_authentication = true`      |

**Différence de modèle :** sur AWS, un sous-réseau appartient à une seule zone de disponibilité (il faut un subnet par AZ pour la haute disponibilité). Sur Azure, un sous-réseau peut couvrir plusieurs zones, la redondance étant portée par la ressource (VM Scale Set zone-redundant, etc.).

---

## Question de fond — Capital One et IMDSv2

**Ce que IMDSv2 aurait changé :**
L'attaque SSRF de mars 2019 reposait sur un simple GET vers `http://169.254.169.254/latest/meta-data/iam/security-credentials/`. Avec IMDSv2, un jeton obtenu par PUT avec en-tête personnalisé (`X-aws-ec2-metadata-token-ttl-seconds`) est requis. Une primitive SSRF classique ne forge pas cette requête → l'accès aux identifiants IAM temporaires aurait été **bloqué**.

**Ce que IMDSv2 n'aurait pas changé :**
Le rôle IAM du WAF disposait du privilège `s3:ListAllMyBuckets` sur ~700 buckets — une violation flagrante du **moindre privilège**. Même sans SSRF, un attaquant ayant obtenu ces identifiants par un autre vecteur aurait pu exfiltrer les mêmes données (106 millions de personnes impactées, 80 M$ d'amende OCC). IMDSv2 ne corrige pas le sur-privilège IAM.

---

## Destruction et facturation

```bash
$ terraform destroy

aws_route_table_association.public: Destroying...
aws_instance.web: Destroying...
aws_route_table_association.public: Destruction complete after 1s
aws_route_table.public: Destroying...
aws_route_table.public: Destruction complete after 1s
aws_internet_gateway.igw: Destroying...
aws_instance.web: Still destroying... [10s elapsed]
aws_instance.web: Destruction complete after 31s
aws_security_group.web: Destroying...
aws_subnet.public: Destroying...
aws_security_group.web: Destruction complete after 1s
aws_subnet.public: Destruction complete after 1s
aws_internet_gateway.igw: Destruction complete after 23s
aws_vpc.principal: Destroying...
aws_vpc.principal: Destruction complete after 1s

Destroy complete! Resources: 7 destroyed.
```

### Checklist de destruction

- [x] Instances EC2 terminées
- [x] Adresses IP élastiques libérées
- [x] Volumes EBS supprimés (attaché à l'instance, supprimé avec `delete_on_termination = true`)
- [x] Security Groups supprimés
- [x] VPC supprimé
- [x] Aucun coût résiduel visible dans la console Billing
