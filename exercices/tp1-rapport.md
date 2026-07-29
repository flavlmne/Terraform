## Réponses aux questions de synthèse

### 1. Pourquoi `--no-verify` fonctionne-t-il, et quelle est la seule parade réellement efficace ?

Le drapeau `--no-verify` (ou `-n`) est une option cliente du binaire `git` qui déshactive l'exécution des hooks locaux situés dans le répertoire `.git/hooks/` (tels que ceux installés par `pre-commit`). Les hooks locaux s'exécutent entièrement sur la machine du développeur, ce qui en fait un simple **filet de sécurité ergonomique**, mais pas une barrière de sécurité infranchissable.

**La seule parade réellement efficace** repose sur le principe de **médiation complète** côté serveur :
- Exécuter obligatoirement les mêmes contrôles de sécurité et de conformité (`gitleaks`, linters, validation Terraform) dans un pipeline de **CI/CD** (ex. GitHub Actions).
- Mettre en place des **règles de protection de branche** sur `main` interdisant les *pushes* directs, imposant les *pull requests* relues et exigeant la réussite du pipeline CI avant toute fusion.

---

### 2. Le secret que vous avez purgé était-il, à un moment, présent sur le serveur distant ? Qu'auriez-vous dû faire en premier s'il avait été réel ?

Dans notre cas pratique, le secret a été commité localement puis purgé avec `git filter-repo` avant d'être poussé. Il n'a donc **jamais été présent sur le serveur distant** (GitHub).

Si le secret avait été réellement poussé sur le serveur distant :
1. **Action n°1 obligatoire et immédiate : Révoquer le secret chez l'émetteur** (ex. supprimer ou désactiver la clé IAM dans la console AWS). Les dépôts publics sont scannés en continu par des robots d'attaque en quelques secondes. Réécrire l'historique sans révoquer d'abord donne un faux sentiment de sécurité alors que le secret est déjà compromis.
2. **Générer un nouveau secret** et le stocker dans un coffre-fort de secrets (ex. AWS Secrets Manager, Vault).
3. **Inspecter les journaux d'audit** (AWS CloudTrail) pour vérifier si la clé a été exploitée pendant la fenêtre d'exposition.
4. **Purger l'historique** du dépôt Git avec `git filter-repo` et forcer la mise à jour des branches distantes.

---

### 3. En quoi la mutabilité des tags Git explique-t-elle l'incident `tj-actions/changed-files` ?

Un tag Git (ex: `v45`) est un simple pointeur nommé vers une empreinte de commit. Contrairement aux commits eux-mêmes, **un tag est techniquement mutable** : toute personne disposant des droits d'écriture sur le dépôt peut forcer un tag à pointer vers un autre commit (`git tag -f v45 <sha_malveillant>` suivi d'un `git push --force --tags`).

Dans l'incident **CVE-2025-30066 (`tj-actions/changed-files`)**, un attaquant ayant compromis les accès du projet a réécrit l'ensemble des tags de version (`v1.0.0` à `v45`) pour qu'ils pointent vers un commit injectant un script d'exfiltration de mémoire (`memdump.py`). Tous les workflows GitHub Actions utilisant la syntaxe avec tag (`uses: tj-actions/changed-files@v45`) ont immédiatement téléchargé le code malveillant lors de leur exécution.

**Leçon de sécurité :** Pour se protéger, il faut appliquer le principe d'immutabilité et **épingler les dépendances par l'empreinte SHA-1 complète du commit** (`uses: tj-actions/changed-files@<sha1_immuable>`) au lieu de s'appuyer sur un tag mutable.

---

### 4. Citez trois éléments du dépôt qui relèvent de la *gestion de configuration* au sens ITIL du terme.

Au sens ITIL / ITSM, la gestion des configurations consiste à identifier, enregistrer et suivre la totalité des éléments de configuration (**CI - Configuration Items**) d'un système d'information et leurs relations au sein d'une **CMDB**.

Dans notre dépôt IaC, qui fait office de CMDB exécutable :
1. **Les fichiers Terraform (`terraform/main.tf` et `variables.tf`)** : Définissent la liste exacte et les attributs des éléments de configuration d'infrastructure (instances EC2, type d'instance `t2.micro`, subnets, security groups, région).
2. **Le playbook Ansible (`ansible/localhost/playbook.yml`)** : Décrit les éléments de configuration logicielle à appliquer sur les machines cibles (fichiers `index.html`, `styles.css`, `main.js`, arborescence).
3. **Le fichier `.pre-commit-config.yaml` (et `.gitattributes` / `Makefile`)** : Définit les règles de référence (*baseline*) et d'exigences de qualité et de sécurité applicables à l'ensemble du projet d'infrastructure.
