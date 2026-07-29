# Réponses aux exercices du Module 1

## Exercice 1.1 — Lire un script comme une machine
**Ce qu'affiche le script :**
Le script va afficher : `Créé dans $DOSSIER` sans évaluer la variable. De plus, il y aura une erreur de syntaxe à la ligne 2.

**Bugs identifiés :**
1. **L'affectation de variable avec espaces :** `DOSSIER = "/tmp/projet"` est invalide en Bash. Il ne doit y avoir aucun espace autour du signe `=`. Bash va interpréter `DOSSIER` comme une commande à exécuter. En conséquence, la variable `$DOSSIER` sera vide et `mkdir -p` créera juste un dossier sans nom (ce qui échouera).
2. **Guillemets simples vs doubles :** `echo 'Créé dans $DOSSIER'` utilise des guillemets simples (`'`). En Bash, les guillemets simples empêchent l'expansion des variables. Le script affichera donc littéralement `Créé dans $DOSSIER`.

## Exercice 1.2 — Le pipeline vert menteur
**Explication :**
- `bash -c 'commande_inexistante | tee /tmp/log' ; echo $?` : Renvoie `0`. Dans un pipeline classique (avec `|`), Bash renvoie le code de retour de la **dernière** commande exécutée dans le pipeline. Ici, `tee /tmp/log` réussit (code `0`), donc le pipeline complet renvoie `0`.
- `bash -c 'set -o pipefail; commande_inexistante | tee /tmp/log' ; echo $?` : Renvoie `127`. Avec `set -o pipefail`, le code de retour du pipeline est celui de la **première** commande qui échoue. `commande_inexistante` renvoie `127`, donc le pipeline renvoie `127`.

**Lien avec la CI/CD :**
Dans un pipeline, si l'on utilise un "pipe" (ex: `terraform plan | tee plan.log`), et qu'une erreur survient à la première étape, sans `pipefail`, l'étape sera considérée en succès (`0`) par la CI. Le pipeline passe au "vert" alors que le déploiement a échoué.

## Exercice 1.3 — Reproduire et réparer la panne
La commande `bash hello.sh` va soit échouer avec "command not found" sur `echo "monde"\r` soit afficher un comportement étrange à cause du retour chariot (CR, `\r`).
Pour réparer sans réécrire le fichier :
```bash
tr -d '\r' < hello.sh > hello_fixed.sh && mv hello_fixed.sh hello.sh
```
ou
```bash
sed -i 's/\r$//' hello.sh
```
ou `dos2unix hello.sh` si installé.

Fichier `.gitattributes` qui aurait empêché le problème :
```gitattributes
* text=auto eol=lf
*.sh text eol=lf
```

## Exercice 1.4 — Votre premier Makefile
Si on crée un fichier `clean` vide à la racine du projet et qu'on retire la ligne `.PHONY` du `Makefile`, la commande `make clean` affichera :
```
make: 'clean' is up to date.
```
C'est parce que `make` considère `clean` comme un fichier cible. Puisque le fichier existe et qu'il n'a pas de prérequis, `make` estime qu'il n'y a rien à faire pour le construire (il est "à jour"). La directive `.PHONY: clean` indique à `make` que `clean` n'est pas un fichier mais une action.
