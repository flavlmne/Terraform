# Rapport TP 2 — Déploiement multi-cloud sécurisé

**Auteur :** Flavien Lemoine
**Dépôt :** <https://github.com/flavlmne/Terraform>
**Environnements :** AWS `envs/dev-aws`, Azure `envs/dev-azure`

## Contrôles réalisés sur le code

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- `trivy config --severity HIGH,CRITICAL`
- `pre-commit` et Gitleaks

Ces contrôles valident le code sans créer de ressource cloud.

## Partie A — État distant

### AWS

Le script `scripts/bootstrap-aws-backend.sh` crée un bucket S3 avec :

- Block Public Access complet ;
- versioning ;
- chiffrement côté serveur AES-256 ;
- verrouillage natif Terraform via `use_lockfile = true`.

La configuration effective est fournie localement dans
`envs/dev-aws/backend.hcl`, fichier ignoré par Git.

### Azure

Le script `scripts/bootstrap-azure-backend.sh` crée un groupe de ressources, un
compte StorageV2, active le versioning des blobs et crée un conteneur privé. Le
backend utilise Microsoft Entra ID avec `use_azuread_auth = true`.

La configuration effective est fournie localement dans
`envs/dev-azure/backend.hcl`, fichier ignoré par Git.

## Parties B et C — Déploiements

### Résultats AWS

- Nombre de ressources annoncées par le plan : **à relever après `make plan-aws`**
- URL nginx : **à relever après application**
- Vérification HTTP : **à joindre**

### Résultats Azure

- Nombre de ressources annoncées par le plan : **à relever après `make plan-azure`**
- URL nginx : **à relever après application**
- Vérification HTTP : **à joindre**

Les valeurs ci-dessus doivent provenir des comptes cloud utilisés. Elles ne
sont pas inventées dans ce rapport.

## Partie D — Détection et réconciliation de la dérive

Après ouverture manuelle du port SSH à `0.0.0.0/0` dans la console AWS,
Terraform doit comparer la configuration distante au code et afficher une
modification du groupe de sécurité. Le plan propose de retirer la règle
publique et de rétablir `var.cidr_admin`.

### Sortie réelle du plan

```text
À COLLER : sortie de `terraform -chdir=envs/dev-aws plan`
montrant la règle SSH 0.0.0.0/0 supprimée et le CIDR /32 restauré.
```

### Interprétation

La modification manuelle constitue une dérive : l'état réel n'est plus
conforme à la source de vérité versionnée. Terraform la détecte lors du
rafraîchissement, puis propose une réconciliation vers le CIDR administratif
`/32`. Un `apply` validé remet donc le groupe de sécurité dans l'état attendu.

## Informations sensibles observables dans un tfstate

Même sans mot de passe déclaré, un état peut révéler notamment :

1. les adresses IP publiques et privées des VM ;
2. les identifiants, ARN, noms de ressources, réseaux et groupes de sécurité ;
3. les données d'initialisation (`user_data`/`custom_data`) et certaines
   métadonnées de configuration.

Le contrôle principal est un backend distant privé, chiffré, versionné et
protégé par des droits IAM/RBAC minimaux. Le verrouillage empêche les écritures
concurrentes. Le fichier d'état et les plans ne sont jamais versionnés dans Git.

## Comparatif AWS / Azure

| Fonction | AWS | Azure |
|---|---|---|
| Conteneur logique | Compte/région | Resource Group |
| Réseau virtuel | `aws_vpc` | `azurerm_virtual_network` |
| Sous-réseau | `aws_subnet` | `azurerm_subnet` |
| Accès Internet | Internet Gateway + route table | IP publique Standard |
| Pare-feu | Security Group | Network Security Group |
| Association réseau/pare-feu | SG attaché à EC2 | Association NIC/NSG |
| Interface réseau | Implicite sur EC2 | `azurerm_network_interface` |
| Adresse publique | IP publique EC2 | `azurerm_public_ip` |
| Machine Linux | `aws_instance` | `azurerm_linux_virtual_machine` |
| Initialisation nginx | `user_data` | `custom_data` |
| Clé SSH | Paire de clés EC2 existante | Clé publique injectée |
| Chiffrement disque | `root_block_device.encrypted = true` | Managed Disk chiffré par la plateforme |
| État distant | S3 versionné/chiffré | Azure Blob versionné/chiffré |
| Verrouillage | Fichier de verrou S3 | Lease natif Azure Blob |

## Capital One et IMDSv2

IMDSv2 aurait exigé une requête `PUT` avec un en-tête spécifique pour obtenir
un jeton avant de lire les métadonnées, ce qu'une SSRF simple réalise
difficilement. Il aurait donc réduit le risque de vol des identifiants du rôle
EC2. Il n'existait toutefois pas en mars 2019 et n'aurait pas corrigé les
permissions S3 excessives du rôle compromis : le moindre privilège restait
indispensable.

## Destruction et preuve de facturation

Commandes finales :

```bash
make destroy-aws
make destroy-azure
```

Après destruction, vérifier les deux consoles et joindre la capture demandée
dans `docs/captures/facturation-fin-tp.png`.

**Capture de facturation : à produire depuis les comptes cloud après
destruction réelle.**
