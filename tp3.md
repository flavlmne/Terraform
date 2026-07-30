M A S T È R E C Y B E R S É C U R I T É — 4 ᵉ A N N É E · G E S T I O N D E S C O N F I G U R AT I O N S & I A C
MODULE 3
Infrastructure as Code et
Terraform
Du concept déclaratif au premier déploiement réel sur AWS et Azure. Lan‐
gage HCL, cycle de vie, fichier d'état, modules, et les contrôles de sécurité
sans lesquels l'IaC industrialise les mauvaises configurations au lieu de les
supprimer.
JOUR 2 — 7 H NIVEAU : CŒUR DU COURS PRATIQUE : 3 H
Formateur : Boris Rose
Gestion des configurations et Infrastructure as Code
Terraform · Ansible · Docker · CI/CD
BC
D E S I G N S Y S T E M S
MODULE 3 Sommaire
Sommaire
L'Infrastructure as Code : concepts
Définition
Impératif et déclaratif
Ce que l'IaC apporte à la sécurité
Terraform : présentation et histoire
Architecture
L'histoire de la licence — à connaître
Installation
Le langage HCL
Structure d'un bloc
Types de données
Variables : les quatre attributs qui comptent
Références, locals, outputs
Boucles : count et for_each
Expressions utiles
Le cycle de vie Terraform
Les cinq commandes
init : ce qu'il fait vraiment
plan : le cœur du modèle
apply et destroy
Le fichier d'état : le sujet le plus important
Ce que c'est
Backends distants
Chiffrer et éviter les secrets dans l'état
Refactoriser sans casser : moved, import, removed
Premier déploiement réel : AWS et Azure
Préparation des comptes
Tableau d'équivalence AWS ↔ Azure
Un serveur web sur AWS
Le même service sur Azure
Modules
TP 2 — Déploiement multi-cloud sécurisé
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 2
MODULE 3 C H A P I T R E 1
L'Infrastructure as Code : concepts
L'Infrastructure as Code : concepts
◎ OBJECTIFS DU CHAPITRE
À l'issue de ce chapitre, vous saurez :
•
•
•
•
définir l'IaC et la distinguer d'un simple script d'automatisation ;
expliquer la différence entre impératif et déclaratif, et pourquoi elle change tout ;
définir idempotence, convergence, immutabilité, dérive et réconciliation ;
énoncer les apports de l'IaC à la sécurité — et les risques nouveaux qu'elle introduit.
Définition
◆ DÉFINITION — INFRASTRUCTURE AS CODE (IAC)
Pratique consistant à décrire une infrastructure informatique dans des fichiers texte versionnés,
puis à confier à un outil le soin de créer, modifier et détruire les ressources réelles pour qu'elles
correspondent à cette description.
Le point essentiel n'est pas « écrire du code » : c'est que la description devient la source de vérité
unique. La console web du fournisseur cloud n'est plus qu'un outil de lecture.
Ce n'est pas la même chose qu'un script d'automatisation :
SCRIPT ( BASH , AWS CLI ) IAC (TERRAFORM)
Décrit la suite d'actions à effectuer l'état final souhaité
Rejouable rarement (« la ressource existe déjà ») oui, par construction
Sait supprimer non, sauf à l'écrire oui, il connaît ce qu'il a créé
Sait détecter une dérive non oui ( plan )
Connaît les dépendances l'auteur les ordonne à la main déduites, graphe automatique
Impératif et déclaratif
◆ DÉFINITION — IMPÉRATIF
On décrit comment faire, étape par étape. « Crée un réseau. Puis crée un sous-réseau dedans. Puis
lance une machine. »
Le résultat dépend de l'état de départ : rejouer le script sur une infrastructure existante produit soit
des doublons, soit des erreurs.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 3
MODULE 3 L'Infrastructure as Code : concepts
◆ DÉFINITION — DÉCLARATIF
On décrit ce qui doit exister, sans dire comment y parvenir. « Il doit exister un réseau 10.0.0.0/16, un
sous-réseau 10.0.1.0/24 dedans, et une machine dans ce sous-réseau. »
L'outil compare cette description à la réalité et calcule lui-même les actions nécessaires — création,
modification, destruction, ou rien du tout.
# Impératif : que se passe-t-il si je le lance deux fois ?
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-subnet --vpc-id vpc-abc --cidr-block 10.0.1.0/24
# Déclaratif : le lancer dix fois donne exactement le même résultat
resource "aws_vpc" "principal" {
cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "app" {
vpc_id = aws_vpc.principal.id # dépendance déduite automatiquement
cidr_block = "10.0.1.0/24"
}
◆ DÉFINITION — IDEMPOTENCE
Propriété d'une opération dont l'exécution répétée produit exactement le même résultat que
l'exécution unique.
Formellement : f(f(x)) = f(x).
Exemple non idempotent : echo "ligne" >> fichier (ajoute une ligne à chaque appel). Exemple
idempotent : echo "ligne" > fichier (le fichier contient toujours une ligne).
C'est la propriété qui rend l'automatisation sûre à rejouer. Sans elle, on n'ose plus relancer, donc on
n'automatise pas vraiment.
◆ DÉFINITION — CONVERGENCE
Processus par lequel un système est progressivement amené vers son état désiré, à chaque
exécution de l'outil. C'est le modèle d'Ansible et de Puppet : on répare l'existant.
◆ DÉFINITION — IMMUTABILITÉ
Modèle opposé à la convergence : on ne modifie jamais une ressource en place. Pour la changer, on
en construit une neuve à partir de la description, on bascule le trafic, puis on détruit l'ancienne.
C'est le modèle des conteneurs, des images machine (AMI), et de Terraform pour les ressources qui
ne peuvent pas être modifiées à chaud ( ForceNew ).
Avantage de sécurité majeur : une machine immuable n'accumule ni dérive, ni correctifs partiels, ni
implants persistants. Un attaquant qui obtient une persistance sur une instance la perd au prochain
déploiement.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 4
MODULE 3 L'Infrastructure as Code : concepts
★ CONVERGENCE CONTRE IMMUTABILITÉ : CE N'EST PAS UN CHOIX BINAIRE
En production, on combine les deux : Terraform gère l'immuable (instances remplacées, images de
conteneur), Ansible gère le convergent (configuration fine, correctifs d'urgence, machines physiques
ou héritées). Le module 5 traite de leur articulation.
Ce que l'IaC apporte à la sécurité
★ À RETENIR
1.
2.
3.
4.
5.
Revue avant application. Un changement d'infrastructure passe par une pull request, relue par
un pair, analysée par un scanner de sécurité — avant de toucher la production. C'est le seul
moment où une erreur ne coûte rien.
Traçabilité complète. Qui, quoi, quand, pourquoi. Sans exception, y compris pour les
changements d'urgence.
Reproductibilité. On reconstruit une infrastructure saine depuis un commit connu, au lieu de
restaurer une sauvegarde potentiellement déjà compromise.
Conformité programmable. « Aucun bucket public », « chiffrement obligatoire », « IMDSv2 requis
» deviennent des règles automatiques, vérifiées à chaque commit (module 6).
Réduction des accès permanents. Si tout passe par le pipeline, plus personne n'a besoin d'un
compte administrateur permanent en production.
⬢ LE REVERS : L'IAC INDUSTRIALISE AUSSI LES ERREURS
Une mauvaise configuration écrite dans un module réutilisé par vingt équipes est déployée vingt fois.
La rapidité joue dans les deux sens.
Les chiffres (à présenter comme des ordres de grandeur, chaque étude ayant sa méthodologie) :
•
•
•
Bridgecrew, 2020 — scan de ~2 600 modules du Terraform Registry public contre les
benchmarks CIS : 44 % des modules contiennent au moins une mauvaise configuration. Ces
modules avaient été téléchargés plus de 15 millions de fois. Catégories dominantes : sauvegarde,
journalisation, chiffrement.
Unit 42, Cloud Threat Report vol. 2 (2020) — 22 % des fichiers Terraform et 42 % des fichiers
CloudFormation analysés contiennent au moins une configuration non sécurisée.
Orca Security, State of Application Security 2026 (1 079 organisations, T3 2025 – T1 2026) —
84 % des organisations déploient du stockage non chiffré dans des environnements gérés par
IaC ; 80 % n'y ont aucune journalisation.
Le constat le plus important n'est pas le chiffre mais sa stabilité : les mêmes catégories dominent
à six ans d'écart. Et la cause racine n'est pas l'erreur d'écriture : c'est que les arguments de
sécurité sont optionnels et que leurs valeurs par défaut ne sont pas sûres.
C'est très exactement une violation du principe de valeurs par défaut sûres (fail-safe defaults) de
Saltzer & Schroeder — traité au module 6.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 5
MODULE 3 C H A P I T R E 2
Terraform : présentation et histoire
Terraform : présentation et histoire
◎ OBJECTIFS DU CHAPITRE
•
•
•
Situer Terraform dans son écosystème et comprendre son architecture.
Connaître l'histoire de la licence — sujet d'entretien d'embauche fréquent.
Savoir ce qu'est un provider et comment il est verrouillé.
Architecture
◆ DÉFINITION — TERRAFORM
Outil d'IaC déclaratif édité par HashiCorp (acquis par IBM ; annonce du rachat le 24 avril 2024, 6,4
milliards de dollars). Terraform ne connaît aucune API cloud : toute son intelligence métier réside
dans des providers, des greffons distribués séparément.
┌──────────────────────────────────────────┐ │ Vos fichiers .tf (langage HCL) │ └────────────────────┬─────────────────────┘
▼
┌──────────────────────────────────────────┐ │ Terraform Core │ │ · analyse le HCL │ │ · construit le graphe de dépendances │ │ · compare description ↔ état ↔ réalité │ │ · calcule le plan │ └────────────────────┬─────────────────────┘
▼ (protocole gRPC)
┌──────────────────────────────────────────┐ │ Providers (binaires téléchargés) │ │ hashicorp/aws · hashicorp/azurerm │ │ kreuzwerker/docker · hashicorp/random │ └────────────────────┬─────────────────────┘
▼ (API HTTPS)
AWS · Azure · Docker · …
◆ DÉFINITION — PROVIDER
Greffon qui traduit les ressources déclarées en appels d'API. Chaque provider a une adresse
( namespace/nom ) et un numéro de version.
•
hashicorp/aws — officiel HashiCorp
•
hashicorp/azurerm — officiel HashiCorp
•
kreuzwerker/docker — communautaire : il n'existe pas de provider Docker officiel HashiCorp
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 6
MODULE 3 Terraform : présentation et histoire
L'histoire de la licence — à connaître
2014
Première version publique de Terraform, sous licence MPL 2.0 (open source).
10 août 2023
HashiCorp annonce le passage de MPL 2.0 à BUSL 1.1 (Business Source License) « on all future releases
». La licence interdit l'usage pour fournir « a competitive offering to HashiCorp ». Les versions ≤ 1.5.5
restent MPL 2.0.
25 août 2023
Publication du manifeste OpenTF, appelant HashiCorp à revenir à une licence open source.
20 septembre 2023
Le fork rejoint la Linux Foundation sous le nom OpenTofu, sous licence MPL 2.0. Engagement annoncé :
140+ organisations, 600+ personnes, au moins 18 développeurs à plein temps sur cinq ans.
24 avril 2024
IBM annonce le rachat de HashiCorp (35 $/action, valeur d'entreprise 6,4 Md$).
★ TERRAFORM OU OPENTOFU ?
Les deux outils sont largement compatibles : mêmes fichiers .tf , mêmes providers, mêmes
commandes ( tofu au lieu de terraform ). Ce cours utilise Terraform, car c'est ce que vous
rencontrerez majoritairement en entreprise et en entretien.
La différence de fond en 2026 concerne le chiffrement de l'état :
•
•
Terraform ne chiffre pas l'état lui-même : il délègue le chiffrement au backend (S3, Azure Blob) et
cherche à empêcher les secrets d'y entrer via les valeurs éphémères (§ 5.4).
OpenTofu propose depuis la version 1.7.0 (30 avril 2024) un chiffrement applicatif de bout en
bout de l'état et des plans, indépendant du backend (AES-GCM, avec fournisseurs de clés
PBKDF2, AWS KMS, GCP KMS, OpenBao).
C'est l'argument technique le plus souvent avancé en faveur d'OpenTofu.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 7
MODULE 3 Terraform : présentation et histoire
Installation
AWS / LINUX / MACOS
WINDOWS
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
# Ubuntu / Debian
wget -O - https://apt.re‐
leases.hashicorp.com/gpg \
| sudo gpg --dearmor -o /usr/share/key‐
rings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/
hashicorp.gpg] \
https://apt.releases.hashicorp.com $(lsb_
release -cs) main" \
| sudo tee /etc/apt/sources.list.d/hashi‐
corp.list
sudo apt update && sudo apt install terra‐
form
winget install --id HashiCorp.Terraform
# ou
choco install terraform
terraform version
Recommandation du cours : travaillez depuis WSL2,
afin d'avoir le même environnement que les runners
de CI/CD.
terraform version
Activez l'autocomplétion et un formatage automatique dans votre éditeur :
terraform -install-autocomplete
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 8
MODULE 3 Le langage HCL
C H A P I T R E 3
Le langage HCL
◎ OBJECTIFS DU CHAPITRE
Lire et écrire du HCL sans hésitation : blocs, types, variables, expressions, boucles.
Structure d'un bloc
type_de_bloc "étiquette1" "étiquette2" {
argument = expression
bloc_imbriqué {
autre_argument = valeur
}
}
Les types de blocs de premier niveau :
BLOC RÔLE
terraform Version requise, providers requis, backend d'état
provider Configuration d'un provider (région, authentification)
resource Une ressource gérée : Terraform la crée, la modifie, la détruit
data Une donnée lue : Terraform la consulte, ne la gère pas
variable Paramètre d'entrée
output Valeur de sortie
locals Valeurs calculées internes
module Appel à un module réutilisable
import / moved / removed Refactorisation déclarative de l'état
check Assertion de validation post-application
▲ `RESOURCE` CONTRE `DATA` — LA DISTINCTION FONDAMENTALE
resource "aws_vpc" "principal" { cidr_block = "10.0.0.0/16" } # Terraform le CRÉE
data "aws_vpc" "existant" { id = "vpc-0123456789abcdef0" } # Terraform le LIT
Une data source est en lecture seule : elle sert à référencer quelque chose qui existe déjà (créé par
une autre équipe, par une autre racine Terraform, ou à la main). Un terraform destroy ne détruit
jamais une data source.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 9
MODULE 3 Le langage HCL
Types de données
# Primitifs
string = "texte"
number = 42
bool = true
# Collections
list(string) map(string) = ["a", "b", "c"] # ordonnée, indexée par entier
set(string) = ["a", "b"] # non ordonnée, sans doublon
= { env = "dev", eq = "infra" }
# Structurels
object({ nom = string, taille = number })
tuple([string, number, bool])
Variables : les quatre attributs qui comptent
variable "environnement" {
description = "Nom de l'environnement cible." type = string
default = "dev"
# OBLIGATOIRE en pratique
validation {
condition = contains(["dev", "staging", "prod"], var.environnement)
error_message = "environnement doit valoir dev, staging ou prod."
}
}
variable "mot_de_passe_bdd" {
description = "Mot de passe initial de la base."
type = string
sensitive = true # masque la valeur dans les logs et l'UI
}
▲ `SENSITIVE = TRUE` NE CHIFFRE RIEN
C'est le malentendu le plus dangereux de Terraform. La documentation HashiCorp est explicite :
l'argument sert à « redact those values from Terraform CLI log output and the HCP Terraform UI ».
Sa portée est l'affichage, et uniquement l'affichage.
La valeur est stockée en clair dans le fichier d'état. Et :
« If you use the terraform output CLI command with the -json or -raw flags,
Terraform displays sensitive outputs in plain text. »
Nous traitons ce problème au chapitre 5.
Quatre façons de fournir une valeur, par priorité croissante :
MÉTHODE EXEMPLE USAGE
default dans le bloc default = "dev" valeur de repli
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 10
MODULE 3 Le langage HCL
MÉTHODE EXEMPLE USAGE
Fichier terraform.tfvars environnement = "dev" chargé automatiquement
Variable d'environnement export TF_VAR_environnement=prod CI/CD et secrets
Ligne de commande -var="environnement=prod" ponctuel, prioritaire
★ POUR LES SECRETS, UTILISEZ `TF_VAR_`
export TF_VAR_mot_de_passe_bdd="$(vault kv get -field=password secret/bdd)"
terraform apply
Le secret ne touche jamais le disque, ne passe pas dans l'historique du shell (avec $(...) ), et
n'apparaît pas dans un fichier versionnable. Ce n'est pas parfait — il reste dans l'environnement du
processus, donc lisible via /proc/<pid>/environ — mais c'est nettement mieux qu'un .tfvars.
Références, locals, outputs
locals {
prefixe = "${var.projet}-${var.environnement}"
etiquettes_communes = {
Projet = var.projet
Environment = var.environnement
ManagedBy = "terraform"
Owner = var.equipe
}
}
resource "aws_vpc" "principal" {
cidr_block = var.cidr_vpc
enable_dns_hostnames = true
tags = merge(local.etiquettes_communes, { Name = "${local.prefixe}-vpc" })
}
output "id_vpc" {
description = "Identifiant du VPC créé."
value = aws_vpc.principal.id
}
Syntaxe des références :
CIBLE SYNTAXE
Ressource aws_vpc.principal.id
Data source data.aws_ami.ubuntu.id
Variable var.environnement
Local local.prefixe
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 11
MODULE 3 Le langage HCL
CIBLE SYNTAXE
Sortie de module module.reseau.id_subnet
Ressource avec count aws_subnet.app[0].id
Ressource avec for_each aws_subnet.app["eu-west-3a"].id
Boucles : count et for_each
# count : indexation par ENTIER
resource "aws_subnet" "public" {
count = 3
vpc_id = aws_vpc.principal.id
cidr_block = cidrsubnet(var.cidr_vpc, 8, count.index)
}
# for_each : indexation par CLÉ
resource "aws_subnet" "public" {
for_each = toset(["eu-west-3a", "eu-west-3b", "eu-west-3c"])
vpc_id = aws_vpc.principal.id
availability_zone = each.key
cidr_block = cidrsubnet(var.cidr_vpc, 8, index(var.zones, each.key))
}
▲ PRÉFÉREZ `FOR_EACH` À `COUNT` — PRESQUE TOUJOURS
Avec count , l'identité d'une ressource dans l'état est son indice. Si vous retirez le premier élément
d'une liste de trois, tous les indices se décalent :
aws_subnet.public[0] → détruit puis recréé avec le contenu de l'ancien [1]
aws_subnet.public[1] → détruit puis recréé avec le contenu de l'ancien [2]
aws_subnet.public[2] → détruit
Terraform détruit et recrée trois sous-réseaux alors que vous vouliez en supprimer un. En
production, cela peut signifier une interruption de service.
Avec for_each , l'identité est une clé stable : retirer "eu-west-3a" ne détruit que
aws_subnet.public["eu-west-3a"].
Réservez count au cas booléen : count = var.activer_nat ? 1 : 0.
Expressions utiles
# Conditionnelle
instance_type = var.environnement == "prod" ? "t3.large" : "t3.micro"
# Boucle for
noms_majuscules = [for n in var.noms : upper(n)]
map_par_zone = { for s in aws_subnet.public : s.availability_zone => s.id }
# Fonctions fréquentes
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 12
MODULE 3 Le langage HCL
cidrsubnet("10.0.0.0/16", 8, 2) # → "10.0.2.0/24"
merge(map1, map2)
lookup(map, "clé", "défaut")
try(expression_risquée, "repli")
file("${path.module}/cloud-init.yaml")
templatefile("${path.module}/nginx.conf.tpl", { port = 8080 })
jsonencode({ Version = "2012-10-17", Statement = [...] })
terraform console > cidrsubnet("10.0.0.0/16", 8, 5)
"10.0.5.0/24"
# bac à sable pour tester une expression
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 13
MODULE 3 C H A P I T R E 4
Le cycle de vie Terraform
Le cycle de vie Terraform
◎ OBJECTIFS DU CHAPITRE
Maîtriser init , validate , plan , apply , destroy et comprendre ce qui se passe à chaque étape.
Les cinq commandes
terraform init # 1. télécharge les providers, configure le backend
terraform fmt # 2. formate le code (canonique)
terraform validate # 3. vérifie la syntaxe et la cohérence interne
terraform plan # 4. calcule les actions nécessaires — NE MODIFIE RIEN
terraform apply # 5. exécute
terraform destroy # 6. supprime tout ce que cette racine gère
init : ce qu'il fait vraiment
1.
2.
3.
Lit le bloc required_providers et télécharge les binaires dans .terraform/providers/.
Écrit ou vérifie .terraform.lock.hcl : versions retenues et empreintes SHA-256 des binaires.
Configure le backend d'état (§ 5.3).
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.46.0...
- Installed hashicorp/aws v6.46.0 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above.
★ `.TERRAFORM.LOCK.HCL` SE VERSIONNE, `.TERRAFORM/` S'IGNORE
Le fichier de verrouillage garantit que tous les postes et le pipeline utilisent le même binaire, vérifié
par empreinte. C'est un contrôle d'intégrité de chaîne d'approvisionnement — exactement ce qui
manquait dans l'affaire Codecov.
terraform init -upgrade # met à jour dans les bornes autorisées
▲ LES MODULES NE BÉNÉFICIENT PAS DE CETTE GARANTIE
Point crucial, documenté par la recherche de Boost Security Labs (22 juin 2023) : contrairement aux
providers, les modules Terraform ne sont pas verrouillés par empreinte dans
.terraform.lock.hcl.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 14
MODULE 3 Le cycle de vie Terraform
Un module référencé par un tag Git peut donc voir ce tag déplacé sans qu'aucune vérification ne s'y
oppose — exactement le défaut exploité contre tj-actions/changed-files (module 2).
Plusieurs centaines de modules vulnérables ont été identifiés parmi les 13 000+ du registre public.
Parade : référencer les modules externes par empreinte de commit :
module "vpc" {
source = "git::https://github.com/org/modules.git//vpc?ref=8f4c2b1e9d...".
}
Source : https://labs.boostsecurity.io/articles/erosion-of-trust-unmasking-supply-chain-
vulnerabilities-in-the-terraform-registry/
plan : le cœur du modèle
terraform plan compare trois choses :
1. Votre configuration (.tf) ← ce que vous voulez
2. Le fichier d'état (.tfstate) ← ce que Terraform croit avoir créé
3. La réalité (API du fournisseur) ← ce qui existe vraiment
Symboles de sortie :
SYMBOLE SIGNIFICATION
+ création
- destruction
~ modification en place
-/+ destruction puis recréation — la ligne à surveiller
<= lecture d'une data source
▲ `-/+` : LISEZ TOUJOURS LA RAISON
# aws_instance.web must be replaced
-/+ resource "aws_instance" "web" {
~ ami = "ami-0aaa" -> "ami-0bbb" # forces replacement
Le commentaire # forces replacement indique l'attribut responsable. Certains attributs ne peuvent
pas être modifiés à chaud par l'API du fournisseur : les changer implique de détruire et recréer.
En production, un 6).
-/+ non anticipé sur une base de données, c'est une perte de données. C'est
pour cela que le plan se relit — et que le pipeline le publie en commentaire de pull request (module
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 15
MODULE 3 Le cycle de vie Terraform
terraform plan -out=tfplan # enregistre le plan (binaire)
terraform apply tfplan # applique EXACTEMENT ce plan, sans confirmation
terraform show -json tfplan | jq . # inspection programmatique (utile pour OPA)
★ TOUJOURS `PLAN -OUT` PUIS `APPLY <FICHIER>` EN CI/CD
Sans cela, apply recalcule un plan qui peut différer de celui qui a été relu et approuvé —
l'infrastructure ayant changé entre-temps. La séparation plan/apply est le point de contrôle humain
de tout pipeline IaC.
⬢ `TERRAFORM PLAN` EXÉCUTE DU CODE ARBITRAIRE
Contre-intuitif, et essentiel pour un cours de cybersécurité : plan n'est pas une opération en
lecture seule.
Les vecteurs documentés :
1.
Un provider malveillant publié au registre est téléchargé par init et exécuté comme binaire
local pendant plan (Alex Kaskasoli, 11 mai 2021).
2.
La data source external exécute un programme local et lit sa sortie JSON.
3.
La data source http exfiltre par l'URL ; la data source dns permet du tunneling.
4.
Les provisioners local-exec et remote-exec.
Taxonomie la plus complète : Tenable, 18 novembre 2024. Le point clé qu'ils soulignent : « tout
développeur pouvant ouvrir une pull request » peut ainsi déclencher l'exécution de code sur le
runner de CI.
Pen Test Partners (15 août 2025) a démontré qu'un jeton HCP Terraform disposant uniquement de la
permission « plan » permet, via un speculative plan, d'obtenir une exécution de code sur le runner et
d'en extraire les identifiants AWS/GCP — contournant les restrictions VCS, la MFA et l'accès
conditionnel.
Cadre normatif : c'est le risque CICD-SEC-04 « Poisoned Pipeline Execution » de l'OWASP Top 10
CI/CD.
Contrôles : - Ne jamais exécuter plan sur du code non revu venant d'un fork. - Runner éphémère,
sans secrets de production, avec filtrage des flux sortants. - Liste blanche de providers au niveau
organisation ( terraform.rc / miroir interne). - Interdire pull_request_target avec checkout du
code de la PR (module 6).
apply et destroy
terraform apply terraform apply -auto-approve terraform destroy
terraform destroy -target=aws_instance.web # affiche le plan puis demande confirmation
# ⚠️ pas de confirmation — réservé à la CI, après approbation
# une ressource précise (dépannage)
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 16
MODULE 3 Le cycle de vie Terraform
▲ `-TARGET` EST UN OUTIL DE DÉPANNAGE, PAS DE TRAVAIL QUOTIDIEN
Terraform lui-même affiche un avertissement quand vous l'utilisez. Cibler une ressource contourne le
graphe de dépendances et produit un état partiellement convergé, difficile à raisonner. Si vous avez
besoin de -target régulièrement, c'est que votre racine Terraform est trop grosse : découpez-la.
★ DISCIPLINE DE COÛT, OBLIGATOIRE DANS CE COURS
Vous travaillez sur de vrais comptes AWS et Azure. À la fin de chaque séance :
make destroy # ou : terraform destroy
Vérifiez ensuite dans la console qu'il ne reste rien : adresses IP élastiques non attachées, volumes
EBS orphelins, NAT gateways, snapshots. Ce sont ces ressources-là qui produisent les factures
surprises, pas les instances.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 17
MODULE 3 Le fichier d'état : le sujet le plus important
C H A P I T R E 5
Le fichier d'état : le sujet le plus important
◎ OBJECTIFS DU CHAPITRE
•
•
•
Comprendre ce qu'est le tfstate , pourquoi il existe et ce qu'il contient.
Savoir pourquoi c'est le fichier le plus sensible de votre infrastructure.
Mettre en place un backend distant sécurisé, sur AWS et sur Azure.
Ce que c'est
◆ DÉFINITION — FICHIER D'ÉTAT (STATE)
Fichier JSON, nommé par défaut terraform.tfstate , dans lequel Terraform enregistre la
correspondance entre les objets déclarés dans votre code et les objets réels chez le fournisseur,
ainsi qu'un cache de tous leurs attributs.
Sans lui, Terraform serait incapable de savoir que i-0a1b2c3d4e5f , et créerait une nouvelle instance à chaque aws_instance.web apply.
correspond à l'instance
{
"version": 4,
"terraform_version": "1.15.8",
"serial": 12,
"lineage": "3f2b8c1a-...",
"resources": [
{
"mode": "managed",
"type": "aws_db_instance",
"name": "principale",
"instances": [
{
"attributes": {
"id": "db-prod-01",
"username": "admin",
"password": "S3cr3t-en-clair-ici",
"endpoint": "db-prod-01.abc.eu-west-3.rds.amazonaws.com:5432"
}
}
]
}
]
}
⬢ LE FICHIER D'ÉTAT CONTIENT VOS SECRETS EN CLAIR
La documentation HashiCorp le dit sans détour :
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 18
MODULE 3 Le fichier d'état : le sujet le plus important
« Terraform state and plan files contain detailed information about your infrastructure,
including resource attributes and metadata that can contain sensitive values, such as
initial database passwords or API tokens. »
« If you are developing with Terraform locally, Terraform stores your state in a plaintext
file, which includes any secret values you defined in your configuration. »
Et sur la page consacrée à l'état :
« Avoid storing your state in a version control system or other storage solution that
does not support Terraform state locking and secure access control, because doing so
can result in data loss or exposure of secrets stored in the state file. »
Conséquences directes :
1.
Le tfstate ne va JAMAIS dans Git. Un .gitignore correct est la première ligne du projet
(module 2).
2.
sensitive = true ne change rien à ce problème : sa portée est l'affichage.
3.
Quiconque lit le prêt à l'emploi.
tfstate obtient : mots de passe de bases, clés d'API, adresses IP privées,
identifiants de comptes, la topologie complète de votre infrastructure. C'est un plan d'attaque
4.
Le fichier d'état doit être protégé au même niveau que la production elle-même.
Source : https://developer.hashicorp.com/terraform/language/state/sensitive-data
Backends distants
◆ DÉFINITION — BACKEND
Mécanisme définissant où l'état est stocké et comment il est verrouillé. Le backend par défaut est
local (fichier sur votre disque) : inutilisable dès qu'on travaille à plusieurs.
◆ DÉFINITION — VERROUILLAGE D'ÉTAT (STATE LOCKING)
Mécanisme empêchant deux apply simultanés sur le même état. Sans lui, deux ingénieurs qui
appliquent en même temps produisent un état corrompu et des ressources orphelines.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 19
MODULE 3 Le fichier d'état : le sujet le plus important
AWS — BACKEND `S3`
terraform {
backend "s3" {
bucket = "bc-tfstate-prod"
key = "reseau/terra‐
form.tfstate"
region = "eu-west-3"
encrypt = true # SSE
kms_key_id = "alias/tfstate" # SSE-
KMS
use_lockfile = true # ver‐
rouillage natif S3
}
}
Le bucket doit être créé au préalable, avec :
•
versioning activé (permet de revenir à un état
antérieur) ;
•
Block Public Access activé ;
•
chiffrement au repos (SSE-KMS de
préférence) ;
•
politique IAM restreignant l'accès aux seuls
rôles de déploiement ;
•
journalisation des accès.
AZURE — BACKEND `AZURERM`
terraform {
backend "azurerm" {
resource_group_name = "rg-tfstate"
storage_account_name = "sttfstate‐
prod01"
container_name = "tfstate"
key = "reseau.tfstate"
use_azuread_auth = true
}
}
Le compte de stockage doit avoir :
•
versioning des blobs activé ;
•
accès public anonyme désactivé (c'est le
défaut sur les comptes créés depuis août
2023) ;
•
accès par Microsoft Entra ID plutôt que par clé
de compte ( use_azuread_auth = true ) ;
•
verrouillage assuré nativement par le bail
(lease) de blob.
★ LA CONFIGURATION « S3 + TABLE DYNAMODB » EST OBSOLÈTE
Vous trouverez partout, dans les tutoriels antérieurs à 2025, une table DynamoDB pour le
verrouillage. Ce n'est plus nécessaire.
Le verrouillage natif S3 par fichier de verrou a été introduit dans Terraform 1.10.0 (27 novembre
2024) via l'argument use_lockfile , puis rendu généralement disponible en 1.11.0 (27 février 2025).
La documentation du backend indique désormais :
« DynamoDB-based locking is deprecated and will be removed in a future minor
version. »
⚠️ use_lockfile vaut false par défaut : il faut le poser explicitement.
Chiffrer et éviter les secrets dans l'état
L'approche de HashiCorp n'est pas de chiffrer l'état mais d'empêcher les secrets d'y entrer.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 20
MODULE 3 Le fichier d'état : le sujet le plus important
◆ DÉFINITION — VALEURS ÉPHÉMÈRES (EPHEMERAL VALUES)
Introduites en Terraform 1.10.0 (novembre 2024) pour les ressources, variables et sorties ;
complétées en 1.11.0 (février 2025) par les attributs en écriture seule (write-only arguments).
« Ephemeral values are available at the run time of an operation, but Terraform omits
them from state and plan files. »
C'est la réponse structurelle au problème des secrets dans l'état.
# Le secret est lu à l'exécution et n'est JAMAIS persisté
ephemeral "aws_secretsmanager_secret_version" "bdd" {
secret_id = "prod/bdd/password"
}
resource "aws_db_instance" "principale" {
identifier = "db-prod-01"
username = "admin"
# attribut en écriture seule : absent de l'état
password_wo = ephemeral.aws_secretsmanager_secret_version.bdd.secret_string
password_wo_version = 1
}
VERSION MINIMALE FONCTIONNALITÉ
0.15 argument sensitive
1.10 valeurs et ressources ephemeral
1.11 attributs en écriture seule ( *_wo ) sur les ressources gérées
★ TROIS RÈGLES À APPLIQUER SYSTÉMATIQUEMENT
1.
2.
3.
Backend distant, chiffré, versionné, verrouillé — jamais d'état local au-delà d'un bac à sable.
Accès au bucket / compte de stockage réservé aux rôles de déploiement, avec journalisation
d'audit.
Ne faites pas transiter les secrets par Terraform : générez-les côté fournisseur
( aws_secretsmanager_secret , rotation automatique) ou lisez-les en éphémère.
Refactoriser sans casser : moved , import , removed
Trois blocs remplacent avantageusement les anciennes commandes manuelles :
BLOC VERSION REMPLACE
moved 1.1.0 (déc. 2021) terraform state mv
import 1.5.0 (juin 2023) terraform import
removed 1.7.0 (janv. 2024) terraform state rm
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 21
MODULE 3 Le fichier d'état : le sujet le plus important
# Renommer une ressource sans la détruire
moved {
from = aws_instance.serveur_web
to = aws_instance.web
}
# Adopter une ressource créée à la main
import {
to = aws_s3_bucket.logs
id = "bc-logs-prod"
}
# Retirer de l'état SANS détruire la ressource réelle
removed {
from = aws_instance.ancien
lifecycle { destroy = false }
}
★ POURQUOI C'EST MIEUX QUE LES COMMANDES
Les commandes terraform state mv/rm/import s'exécutent sur le poste de quelqu'un, ne laissent
aucune trace dans le dépôt, et doivent être rejouées manuellement dans chaque environnement. Les
blocs sont du code, donc versionnés, relus en pull request et rejoués automatiquement partout.
C'est le principe de traçabilité du module 2 appliqué à la maintenance de l'état.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 22
MODULE 3 Premier déploiement réel : AWS et Azure
C H A P I T R E 6
Premier déploiement réel : AWS et Azure
◎ OBJECTIFS DU CHAPITRE
Déployer une infrastructure minimale mais correctement sécurisée sur les deux fournisseurs, en
maîtrisant les coûts.
Préparation des comptes
AWS
aws --version
aws configure sso # recommandé :
identifiants temporaires
# ou, à défaut :
aws configure # clé d'accès
longue durée
aws sts get-caller-identity
AZURE
az --version
az login
az account show
az account set --subscription "<id>"
Garde-fous obligatoires avant tout apply :
1.
2.
3.
4.
Activez la MFA sur le compte racine et n'utilisez
plus jamais ce compte.
Créez un budget avec alerte par courriel dans
Billing → Budgets (par exemple 5 $).
Travaillez dans une seule région ( eu-west-3 ,
Paris) pour tout retrouver facilement.
Étiquetez tout ( ManagedBy = terraform , Owner
= votrenom ).
Garde-fous obligatoires :
1.
2.
3.
4.
Créez un groupe de ressources dédié par
étudiant : tout supprimer devient trivial.
Créez un budget dans Cost Management +
Billing.
Travaillez dans une seule région
( francecentral ou westeurope ).
Étiquetez tout de la même façon.
▲ LE MODÈLE DE COMPTE GRATUIT AWS A CHANGÉ EN 2025
Depuis l'annonce du 16 juillet 2025, un nouveau compte AWS reçoit 100 USD de crédits à
l'inscription, plus jusqu'à 100 USD supplémentaires via des activités — soit jusqu'à 200 USD. Le free
account plan dure 6 mois ou jusqu'à épuisement des crédits, la première échéance atteinte.
Point à connaître : à l'expiration du plan gratuit, AWS ferme le compte (les données sont
conservées 90 jours). Le passage au plan payant se fait en un clic ; le retour en arrière est
impossible.
Plus de 30 services restent « toujours gratuits » avec des quotas mensuels, sur les deux plans.
⚠️ La documentation AWS est contradictoire sur ce point : la page billing-free-tier.html encore l'ancien modèle « 12 mois / 750 h EC2 t2.micro », valable pour les comptes existants.
Vérifiez toujours l'état réel de votre compte dans la console Billing.
décrit
Côté Azure : 200 USD de crédit utilisables en 30 jours, plus de 20 services gratuits pendant 12 mois
(dont 750 h/mois de VM burstables) et plus de 65 services toujours gratuits.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 23
MODULE 3 Premier déploiement réel : AWS et Azure
Tableau d'équivalence AWS ↔ Azure
CONCEPT AWS AZURE
Machine virtuelle Amazon EC2 Azure Virtual Machines
Réseau virtuel VPC Virtual Network (VNet)
Sous-réseau Subnet (une seule zone de
disponibilité)
Subnet (peut couvrir plusieurs zones)
Pare-feu d'instance Security Group Network Security Group (NSG)
Sortie Internet Internet Gateway + NAT Gateway NAT Gateway
Stockage objet Amazon S3 Azure Blob Storage
Disque de VM EBS Managed Disk
Registre d'images Amazon ECR Azure Container Registry (ACR)
Kubernetes managé Amazon EKS Azure Kubernetes Service (AKS)
Conteneurs sans
serveur
AWS Fargate Azure Container Instances / Container
Apps
Identités AWS IAM / IAM Identity Center Microsoft Entra ID + Azure RBAC
Secrets Secrets Manager, Parameter Store Azure Key Vault
Clés AWS KMS Azure Key Vault
Multi-comptes AWS Organizations Management Groups
État Terraform Bucket S3 Storage Account / conteneur blob
▲ UNE DIFFÉRENCE DE MODÈLE À COMPRENDRE
Sur AWS, un sous-réseau appartient à une seule zone de disponibilité : pour être hautement
disponible, il faut créer un sous-réseau par zone. Sur Azure, un sous-réseau peut couvrir plusieurs
zones, la redondance étant portée par la ressource (VM Scale Set zone-redundant, etc.).
Traduire une architecture d'un cloud à l'autre n'est donc jamais un simple renommage de ressources.
Un serveur web sur AWS
ENVS/DEV/MAIN.TF — AWS : VPC, SOUS-RÉSEAU PUBLIC, GROUPE DE SÉCURITÉ, INSTANCE NGINX
terraform {
required_version = ">= 1.10"
required_providers {
aws = { source = "hashicorp/aws", version = "~> 6.0" }
}
}
provider "aws" {
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 24
MODULE 3 region = var.region
default_tags {
tags = local.etiquettes
}
}
locals {
prefixe = "${var.projet}-${var.environnement}"
etiquettes = {
Projet = var.projet
Environment = var.environnement
ManagedBy = "terraform"
Owner = var.proprietaire
Premier déploiement réel : AWS et Azure
}
}
# ---------------------------------------------------------------- Réseau -----
resource "aws_vpc" "principal" {
cidr_block = "10.20.0.0/16"
enable_dns_support = true
enable_dns_hostnames = true
tags = { Name = "${local.prefixe}-vpc" }
}
}
resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.principal.id
tags = { Name = "${local.prefixe}-igw" }
resource "aws_subnet" "public" {
vpc_id = aws_vpc.principal.id
cidr_block = "10.20.1.0/24"
availability_zone = "${var.region}a"
map_public_ip_on_launch = true
tags = { Name = "${local.prefixe}-public-a" }
}
resource "aws_route_table" "public" {
vpc_id = aws_vpc.principal.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}
tags = { Name = "${local.prefixe}-rt-public" }
}
resource "aws_route_table_association" "public" {
subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.public.id
}
# ------------------------------------------------------ Groupe de sécurité ---
resource "aws_security_group" "web" {
name = "${local.prefixe}-web"
description = "HTTP public, SSH restreint a l'IP de l'administrateur"
vpc_id = aws_vpc.principal.id
ingress {
description = "HTTP depuis Internet"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 25
MODULE 3 Premier déploiement réel : AWS et Azure
}
ingress {
description = "SSH depuis l'IP d'administration UNIQUEMENT"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [var.cidr_admin] # ex. "203.0.113.45/32"
}
egress {
description = "Sortie libre (mises a jour)"
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = { Name = "${local.prefixe}-sg-web" }
}
# -------------------------------------------------------------- Instance -----
data "aws_ami" "ubuntu" {
most_recent = true
owners = ["099720109477"] # Canonical
filter {
name = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
}
}
resource "aws_instance" "web" {
ami = data.aws_ami.ubuntu.id
instance_type = "t3.micro"
subnet_id = aws_subnet.public.id
vpc_security_group_ids = [aws_security_group.web.id]
key_name = var.nom_cle_ssh
# ---- Durcissement obligatoire -------------------------------------------
metadata_options {
http_endpoint = "enabled"
http_tokens http_put_response_hop_limit = 2 = "required" # IMDSv2 imposé
# 2 si conteneurs, 1 sinon
}
root_block_device {
encrypted = true
volume_type = "gp3"
volume_size = 10
}
user_data = <<-EOT
#!/bin/bash
set -euo pipefail
apt-get update
apt-get install -y nginx
echo "<h1>${local.prefixe} — deploye par Terraform</h1>" > /var/www/html/index.html
systemctl enable --now nginx
EOT
tags = { Name = "${local.prefixe}-web" }
}
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 26
MODULE 3 output "url_publique" {
value = "http://${aws_instance.web.public_ip}"
}
Premier déploiement réel : AWS et Azure
⬢ POURQUOI `HTTP_TOKENS = "REQUIRED"` N'EST PAS NÉGOCIABLE
Capital One, 2019 — l'incident cloud le plus enseigné au monde.
Chronologie exacte. Intrusion les 22-23 mars 2019. Signalement externe le 17 juillet 2019. Annonce
publique et plainte le 29 juillet 2019. Soit environ quatre mois de présence non détectée.
La chaîne d'attaque, établie par la plainte du ministère de la Justice américain :
1.
SSRF sur un pare-feu applicatif (WAF) mal configuré, hébergé sur EC2. (Il est identifié comme
ModSecurity par les analyses publiques ; ni Capital One ni le DOJ ne l'ont jamais confirmé.)
2.
Requête vers le service de métadonnées d'instance :
http://169.254.169.254/latest/meta-data/iam/security-credentials/*****-WAF-Role (le nom
du rôle est caviardé dans les documents publics).
3.
Récupération des identifiants temporaires du rôle IAM attaché à l'instance.
4.
aws s3 ls puis aws s3 sync — environ 700 buckets, 30 Go exfiltrés.
Impact : environ 106 millions de personnes (≈100 M aux États-Unis, ≈6 M au Canada), dont ~140
000 numéros de sécurité sociale et ~80 000 numéros de comptes bancaires. Les numéros de carte
et les identifiants de connexion n'ont pas été compromis.
Suites : amende de 80 millions de dollars infligée par l'OCC le 6 août 2020 — au motif d'une
absence d'évaluation de risque préalable à la migration cloud ; règlement collectif de 190 M$ ;
condamnation pénale en 2022, peine cassée en appel le 17 mars 2025 puis réimposée fin 2025 avec
40,7 M$ de restitution.
⚠️ La nuance que tout le monde oublie : IMDSv2 n'existait pas en mars 2019. Il a été annoncé le 19
novembre 2019, soit huit mois après l'intrusion. La seule défense disponible à l'époque était le
moindre privilège IAM — un rôle de WAF n'a aucun besoin de s3:ListAllMyBuckets.
Comment IMDSv2 protège — deux propriétés cumulées :
1.
Il faut d'abord obtenir un jeton par une requête PUT portant un en-tête personnalisé : bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \ -H "X-aws-ec2-metadata-
token-ttl-seconds: 21600") curl -H "X-aws-ec2-metadata-token: $TOKEN" \ http://
169.254.169.254/latest/meta-data/ Une primitive SSRF classique n'émet que des GET sans en-
tête personnalisé : elle ne peut pas forger cette requête.
2.
Le hop limit IP est fixé à 1 par défaut : le paquet ne franchit qu'un saut réseau, ce qui bloque le
relais via un reverse proxy ou un conteneur mal isolé.
Le piège côté Terraform : l'attribut http_tokens n'a aucune valeur par défaut documentée dans le
provider AWS, et le défaut d'AWS reste optional hors AMI marquée imds-support = v2.0 . En
revanche http_put_response_hop_limit vaut 1 par défaut — ce qui casse l'accès aux métadonnées
depuis un conteneur. D'où les deux lignes explicites du code ci-dessus.
Ce que disent les chiffres aujourd'hui : d'après Datadog (State of Cloud Security 2025), 49 %
seulement des instances EC2 imposent IMDSv2 — et à peine 14 % des instances de plus de deux
ans.
Technique MITRE ATT&CK : T1552.005 — Unsecured Credentials: Cloud Instance Metadata API.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 27
MODULE 3 Premier déploiement réel : AWS et Azure
Le même service sur Azure
ENVS/DEV-AZURE/MAIN.TF — AZURE : VNET, SOUS-RÉSEAU, NSG, VM LINUX
terraform {
required_version = ">= 1.10"
required_providers {
azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
}
}
provider "azurerm" {
features {}
}
locals {
prefixe = "${var.projet}-${var.environnement}"
etiquettes = {
projet = var.projet
environment = var.environnement
managed_by = "terraform"
owner = var.proprietaire
}
}
resource "azurerm_resource_group" "principal" {
name = "rg-${local.prefixe}"
location = var.region tags = local.etiquettes
# ex. "francecentral"
}
resource "azurerm_virtual_network" "principal" {
name = "vnet-${local.prefixe}"
address_space = ["10.30.0.0/16"]
location = azurerm_resource_group.principal.location
resource_group_name = azurerm_resource_group.principal.name
tags = local.etiquettes
}
resource "azurerm_subnet" "app" {
name = "snet-app"
resource_group_name = azurerm_resource_group.principal.name
virtual_network_name = azurerm_virtual_network.principal.name
address_prefixes = ["10.30.1.0/24"]
}
resource "azurerm_network_security_group" "web" {
name = "nsg-${local.prefixe}-web"
location = azurerm_resource_group.principal.location
resource_group_name = azurerm_resource_group.principal.name
security_rule {
name = "AutoriserHTTP"
priority = 100
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "80"
source_address_prefix = "Internet"
destination_address_prefix = "*"
}
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 28
MODULE 3 Premier déploiement réel : AWS et Azure
security_rule {
name = "AutoriserSSHAdmin"
priority = 110
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "22"
source_address_prefix = var.cidr_admin
destination_address_prefix = "*"
}
tags = local.etiquettes
}
resource "azurerm_public_ip" "web" {
name = "pip-${local.prefixe}-web"
location = azurerm_resource_group.principal.location
resource_group_name = azurerm_resource_group.principal.name
allocation_method = "Static"
sku = "Standard"
tags = local.etiquettes
}
resource "azurerm_network_interface" "web" {
name = "nic-${local.prefixe}-web"
location = azurerm_resource_group.principal.location
resource_group_name = azurerm_resource_group.principal.name
ip_configuration {
name = "interne"
subnet_id = azurerm_subnet.app.id
private_ip_address_allocation = "Dynamic"
public_ip_address_id = azurerm_public_ip.web.id
}
tags = local.etiquettes
}
}
resource "azurerm_network_interface_security_group_association" "web" {
network_interface_id = azurerm_network_interface.web.id
network_security_group_id = azurerm_network_security_group.web.id
resource "azurerm_linux_virtual_machine" "web" {
name = "vm-${local.prefixe}-web"
location = azurerm_resource_group.principal.location
resource_group_name = azurerm_resource_group.principal.name
size = "Standard_B2ats_v2"
admin_username = "azureuser"
network_interface_ids = [azurerm_network_interface.web.id]
# Jamais de mot de passe : clé publique uniquement
disable_password_authentication = true
admin_ssh_key {
username = "azureuser"
public_key = file(var.chemin_cle_publique)
}
os_disk {
caching = "ReadWrite"
storage_account_type = "Standard_LRS"
}
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 29
MODULE 3 Premier déploiement réel : AWS et Azure
source_image_reference {
publisher = "Canonical"
offer = "ubuntu-24_04-lts"
sku = "server"
version = "latest"
}
custom_data = base64encode(<<-EOT
#!/bin/bash
set -euo pipefail
apt-get update
apt-get install -y nginx
echo "<h1>${local.prefixe} — deploye par Terraform sur Azure</h1>" > /var/www/html/in‐
dex.html
systemctl enable --now nginx
EOT
)
tags = local.etiquettes
}
output "url_publique" {
value = "http://${azurerm_public_ip.web.ip_address}"
}
★ LES CINQ RÉFLEXES DE SÉCURITÉ PRÉSENTS DANS LES DEUX EXEMPLES
1.
2.
3.
4.
5.
SSH jamais ouvert au monde : var.cidr_admin et non 0.0.0.0/0.
Authentification par clé uniquement, jamais par mot de passe.
IMDSv2 imposé côté AWS ( http_tokens = "required" ).
Chiffrement du disque activé explicitement.
Étiquetage systématique : sans Owner et ManagedBy , plus personne ne sait à qui appartient une
ressource au bout de trois semaines — ni si on peut la supprimer.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 30
MODULE 3 Modules
C H A P I T R E 7
Modules
◎ OBJECTIFS DU CHAPITRE
Factoriser du code Terraform réutilisable et comprendre le risque de chaîne d'approvisionnement
associé.
◆ DÉFINITION — MODULE TERRAFORM
Simple répertoire contenant des fichiers .tf . Tout répertoire est un module ; celui depuis lequel
vous lancez terraform est le module racine. Un module appelé reçoit des variable en entrée et
expose des output en sortie — comme une fonction.
Structure standard recommandée par HashiCorp :
modules/reseau/
├── README.md # ce que fait le module, comment l'appeler ├── main.tf # les entrées, par ordre alphabétique ├── outputs.tf # les sorties, par ordre alphabétique └── versions.tf # les ressources ├── variables.tf # required_version et required_providers
# envs/dev/main.tf — appel du module
module "reseau" {
source = "../../modules/reseau"
projet = var.projet
environnement = var.environnement
cidr_vpc = "10.20.0.0/16"
zones = ["eu-west-3a", "eu-west-3b"]
}
resource "aws_instance" "web" {
subnet_id = module.reseau.ids_subnets_publics[0]
# ...
}
Sources possibles :
source = "./modules/reseau" # local
source = "terraform-aws-modules/vpc/aws" source = "git::https://github.com/org/modules.git//vpc?ref=v1.2.0" source = "git::https://github.com/org/modules.git//vpc?ref=8f4c2b1e9d3a..." # registre public
# tag — MUTABLE
# SHA — sûr
★ CONVENTIONS DE CONCEPTION D'UN MODULE
•
Un module ne doit pas contenir de bloc provider : le provider est configuré par la racine et
hérité. Sinon le module devient impossible à utiliser avec plusieurs régions ou plusieurs comptes.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 31
MODULE 3 Modules
•
•
•
Toute variable a une description. Le module est lu par d'autres que vous.
Valeurs par défaut sûres : chiffrement = true , journalisation = true , public = false . Si
l'appelant doit ajouter du code pour être sécurisé, la plupart ne le feront pas. C'est le principe des
fail-safe defaults.
Ne pas sur-abstraire : un module qui expose quarante variables pour couvrir tous les cas est plus
difficile à utiliser que la ressource brute.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 32
MODULE 3 TP 2 — Déploiement multi-cloud sécurisé
C H A P I T R E 8
TP 2 — Déploiement multi-cloud sécurisé
✎ TP 2 — DURÉE : 3 H
Objectif
Déployer, sur AWS et sur Azure, un serveur web nginx accessible publiquement, avec un état distant
chiffré, un accès SSH restreint et les contrôles de sécurité obligatoires. Puis prouver que la dérive de
configuration est détectée.
1
2
3
4
Partie A — Socle et état distant (45 min)
Reprenez votre dépôt tp-iac-<nom> du TP 1. Créez envs/dev-aws/ et envs/dev-azure/.
AWS : créez à la main (console ou CLI) un bucket S3 pour l'état, avec versioning, Block Public
Access et chiffrement activés. Configurez le backend s3 avec encrypt = true et
use_lockfile = true.
Azure : créez un groupe de ressources et un compte de stockage avec versioning des blobs.
Configurez le backend azurerm avec use_azuread_auth = true.
Lancez terraform init dans les deux racines. Vérifiez que .terraform.lock.hcl est créé et
commité, et que .terraform/ est bien ignoré.
1
2
3
4
Partie B — Déploiement AWS (45 min)
Écrivez le code : VPC, IGW, sous-réseau public, table de routage, groupe de sécurité, instance
t3.micro avec nginx via user_data.
Obligatoire : http_tokens = "required" , disque racine chiffré, SSH limité à votre adresse IP
publique ( curl -s https://checkip.amazonaws.com ).
terraform plan -out=dev.tfplan. Relisez le plan intégralement et notez le nombre de
ressources créées.
terraform apply dev.tfplan . Vérifiez l'accès HTTP dans un navigateur.
1
2
3
Partie C — Déploiement Azure (45 min)
Écrivez l'équivalent : groupe de ressources, VNet, sous-réseau, NSG, IP publique, NIC, VM
Linux avec nginx via custom_data.
Obligatoire : disable_password_authentication = true , SSH limité à votre IP.
Déployez et vérifiez.
Partie D — Dérive, état et destruction (45 min)
1
Dans la console AWS, modifiez manuellement le groupe de sécurité pour ouvrir le port 22 à
0.0.0.0/0 . C'est exactement le geste qu'un collègue pressé ferait en production.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 33
MODULE 3 2
TP 2 — Déploiement multi-cloud sécurisé
Lancez terraform plan. Que détecte-t-il ? Que propose-t-il ? Copiez la sortie dans votre
3
4
5
rapport.
Lancez terraform apply pour réconcilier. Vérifiez dans la console.
Inspection de l'état : bash terraform show -json | jq
'.values.root_module.resources[].type' terraform state list Téléchargez le tfstate
depuis S3 et cherchez-y des informations que vous ne voudriez pas voir fuiter. Listez-en trois
dans votre rapport.
terraform destroy sur les deux clouds. Vérifiez dans les consoles qu'il ne reste rien.
1.
2.
3.
4.
5.
Livrable — docs/tp2-rapport.md
Le plan de la partie D, avec votre interprétation de ce que Terraform a détecté.
Les trois informations sensibles trouvées dans le dans votre configuration.
tfstate , et le contrôle qui protège ce fichier
Un tableau comparatif AWS / Azure des ressources que vous avez écrites, ligne par ligne.
Question de fond : votre code impose IMDSv2 sur AWS. Expliquez, en cinq lignes maximum, ce
que cela aurait changé — et ce que cela n'aurait pas changé — dans l'affaire Capital One de
mars 2019.
Une capture de la page de facturation montrant que vous avez bien tout détruit.
C E Q U ' I L FAU T R E T E N I R D U M O D U L E 3
•
•
•
•
•
•
•
•
•
•
L'IaC est déclarative : on décrit l'état voulu, l'outil calcule les actions. D'où l'idempotence.
Terraform est passé sous licence BUSL le 10 août 2023 ; OpenTofu est le fork MPL 2.0 de la Linux
Foundation (20 septembre 2023).
Le cycle est init → validate → plan → apply → destroy. plan se relit toujours, en
particulier les -/+ (destruction/recréation).
terraform plan n'est PAS en lecture seule : c'est le risque CICD-SEC-04 de l'OWASP.
Le tfstate contient les secrets en clair. sensitive = true ne concerne que l'affichage.
Backend distant chiffré, versionné, verrouillé — et jamais dans Git.
Le verrouillage natif S3 ( use_lockfile , GA en 1.11.0) rend DynamoDB obsolète.
Les valeurs éphémères (1.10) et les attributs en écriture seule (1.11) empêchent les secrets d'entrer
dans l'état.
Les providers sont verrouillés par empreinte ( .terraform.lock.hcl ) ; les modules ne le sont pas
— épinglez-les par SHA de commit.
Préférez for_each à count : l'identité par clé évite les destructions en cascade.
http_tokens = "required" n'a pas de valeur par défaut sûre : posez-le explicitement. Capital One,
2019.
BC Design Systems · Mastère Cybersécurité 4A · IaC & Gestion des configurations 34