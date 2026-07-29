# Réponses aux exercices du Module 2

## Exercice 2.1 — Initialiser un dépôt IaC dans les règles
L'arborescence du projet `tp-iac` a été initialisée et les trois commits respectant les Conventional Commits ont été réalisés :
- `build(git): ajoute la configuration git` (pour `.gitattributes` et `.gitignore`)
- `docs: ajoute le fichier README`
- `build(make): ajoute le Makefile de base`

Le dépôt est propre et prêt à recevoir le code IaC.

## Exercice 2.2 — Prouver la faiblesse, puis la corriger
### 1. Usurper l'identité
Dans Git, l'identité d'un commit est du texte libre. On peut facilement l'usurper en modifiant la configuration locale avant le commit :
```bash
git config user.name "Linus Torvalds"
git config user.email "torvalds@linux-foundation.org"
git commit -m "trust me"
```
Le `git log` affichera ensuite "Linus Torvalds" comme auteur du commit, sans aucune vérification.

### 2 & 3. Configurer la signature SSH
Pour configurer la signature avec SSH :
```bash
# Indiquer à Git d'utiliser le format SSH pour les signatures
git config --global gpg.format ssh
# Définir la clé publique à utiliser pour signer (ici l'exemple ed25519)
git config --global user.signingkey ~/.ssh/id_ed25519.pub
# Forcer la signature de tous les commits
git config --global commit.gpgsign true
```
Ensuite, lors d'un nouveau commit, la clé privée SSH correspondante est utilisée pour le signer, ce qui peut être vérifié avec `git log --show-signature`.

### 4. Question de réflexion
**La signature empêche-t-elle l'usurpation du champ Author ?**
Non. Un attaquant peut toujours changer son champ "Author" (`user.name` et `user.email`) dans sa configuration Git locale et faire un commit signé avec *sa propre* clé GPG/SSH. Le commit aura bien le badge de signature, mais l'auteur affiché sera toujours usurpé.

**Que faut-il ajouter côté serveur pour que la garantie soit réelle ?**
La plateforme (GitHub/GitLab) doit faire le lien entre la clé de signature, l'identité de l'utilisateur sur la plateforme, et l'e-mail du commit. De plus, il faut configurer la plateforme et la branche pour qu'elles rejettent tout commit :
1. Qui n'est pas signé.
2. Dont la signature ne correspond pas à l'auteur déclaré du commit (vérification de la propriété de la clé).

## TP 1 — Un dépôt IaC sain, de bout en bout
Les actions attendues du TP incluent :
- Initialisation avec `pre-commit` (framework de hooks pour valider le code avant le commit).
- Mise en place de `gitleaks` via `pre-commit` pour empêcher les secrets d'entrer dans l'historique Git.
- Si un secret fuite par erreur (par ex. en forçant avec `--no-verify`), `make secrets` peut le détecter.
- Si un secret est commité, il **ne faut pas utiliser git rm**, car le secret reste dans l'historique. Il faut d'abord révoquer le secret chez le fournisseur, puis utiliser un outil comme `git filter-repo` pour nettoyer l'historique Git (ce qui réécrit tous les SHAs des commits subséquents).
