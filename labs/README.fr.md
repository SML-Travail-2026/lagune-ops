# 04_Labs · Les huit labs du cours AZM-201

*English version: [README.en.md](README.en.md)*

Cours **AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps**. Quatre jours, trois débutants, en français. Fil rouge : Lagune Services (entreprise fictive, Abidjan, domaine `lagune.example`) et sa boutique OWASP Juice Shop sur Azure App Service.

> **À valider sur le locataire de formation avant la session.** Aucun de ces guides n'a encore été exécuté dans un vrai locataire. Les commandes viennent de pages officielles relues le 5 novembre 2026 (voir `../17_Videos_Jours/sources.md` et la section « Sources » de chaque guide). Les points non vérifiés sont dits dans la section « Points ouverts » de chaque guide.

## Les labs

| Lab | Quand | Durée | Dossier | Ce que l'équipe produit |
|---|---|---|---|---|
| 1 | J1, 13h30 | 60 min | [LAB-01_Depot_lagune-ops](LAB-01_Depot_lagune-ops/README.fr.md) | Le dépôt `lagune-ops` sur GitHub, son miroir GitLab, la carte de l'environnement |
| 2 | J1, 15h15 | 45 min | [LAB-02_Brancher_Claude_Code](LAB-02_Brancher_Claude_Code/README.fr.md) | Claude Code branché à Learn, Azure, GitHub, GitLab ; règles automatiques testées ; journal des hallucinations |
| 3 | J2, 13h30 | 90 min | [LAB-03_Import_CSV_par_PR](LAB-03_Import_CSV_par_PR/README.fr.md) | 20 salariés créés par un script relu en demande de fusion |
| 4 | J2, 15h15 | 45 min | [LAB-04_Audit_des_roles](LAB-04_Audit_des_roles/README.fr.md) | Tableau des rôles jugé, tickets, recherche dans le journal d'audit |
| 5 | J3, 10h30 | 90 min | [LAB-05_Acces_conditionnel](LAB-05_Acces_conditionnel/README.fr.md) | Matrice et quatre règles d'accès conditionnel, activées |
| 6 | J3, 15h15 | reste de la séance | [LAB-06_VM_sauvegardee](LAB-06_VM_sauvegardee/README.fr.md) | Une VM sans IP publique, Bastion, arrêt automatique, sauvegarde, fiche de coût |
| 7 | J4, 08h30 à 12h30 | 4 h | [LAB-07_Terraform_et_pipeline](LAB-07_Terraform_et_pipeline/README.fr.md) | La boutique en ligne par Terraform et pipeline, HTTPS, rapports Trivy et ZAP |
| 8 | J4, 15h15 | 45 min | [LAB-08_Game_Day](LAB-08_Game_Day/README.fr.md) | Trois incidents, un rapport d'incident |


Chaque guide existe aussi en anglais (`README.en.md`).

Les participants partent du dépôt modèle privé `Yolea-Hub/lagune-ops-starter` (accès en lecture par invitation du formateur), pour créer le dépôt de l'équipe dans **l'organisation GitHub gratuite de l'équipe** (`<ORGANISATION>`, par exemple `lagune-ops-nov2026`). Le formateur garde un corrigé privé : il n'est jamais donné aux participants.

## Comment lire un guide

Chaque guide donne : l'objectif, la durée, les rôles, les prérequis, des étapes numérotées avec les commandes exactes, un contrôle **Vérifier** après chaque grande étape, les pièges, le livrable, les points ouverts et les sources.

- Les trois **rôles** (Dev, Ops, Sécurité) tournent chaque jour.
- Les mots entre chevrons (`<PREFIXE>`, `<DOMAINE>`) sont des valeurs à remplacer. Le formateur vous donne les vraies, sauf `<DOMAINE_EQUIPE>` : le nom de domaine de votre équipe, que vous avez acheté avant le cours. Remplacez **aussi les chevrons** : `rg-<PREFIXE>-vm` devient `rg-lagune01-vm`. Laissés tels quels, PowerShell refuse la commande (« The '<' operator is reserved for future use »).
- Les commandes sont écrites pour **PowerShell 7** sous Windows (voir « Votre poste » ci-dessous). Sur macOS ou Linux, les commandes `git`, `gh`, `glab`, `az`, `terraform` et `claude` s'écrivent de la même façon ; les commandes propres à PowerShell (`Set-Location`, `New-Item`, `$env:...`) ont une forme bash donnée quand elle est utile, marquée « macOS ou Linux ».
- Pour **créer ou modifier un fichier** du dépôt (carte, journal, rapport), ouvrez-le dans Visual Studio Code depuis le dossier du dépôt : `code docs\carte-environnement.md`. VS Code enregistre en UTF-8, ce qui garde les accents.
- **Relire la demande de fusion d'un coéquipier** : sur votre poste, vous êtes sur `main`, pas sur sa branche. Donnez donc le numéro de la demande : `gh pr list`, puis `gh pr view <NUMERO>`, `gh pr diff <NUMERO>`, `gh pr review <NUMERO> --approve`.
- Tout le travail passe par une **branche** et une **demande de fusion** relue par un coéquipier.

## Prérequis généraux

- Un ordinateur Windows 10 ou 11, 8 Go de mémoire au minimum, droits d'installation.
- Les outils de la fiche (section 9) : PowerShell 7, Git, Visual Studio Code, Node.js LTS, Azure CLI, Microsoft Graph PowerShell, Terraform, GitHub CLI (`gh`), GitLab CLI (`glab`), Claude Code, Microsoft Authenticator. Chacun répond à sa commande de version.
- **`jq`** (utilisé par les règles automatiques de l'espace de travail ; sous Windows, avec Git Bash). Il n'est pas dans la liste de la fiche.
- Des comptes GitHub et GitLab (gratuits). **L'organisation GitHub gratuite de l'équipe existe avant le J1** (créée par le chef d'équipe, qui y invite ses deux coéquipiers et le formateur : voir LAB-01 et le courriel d'avant-cours). Chacun a accepté l'invitation GitHub au dépôt modèle `Yolea-Hub/lagune-ops-starter`, reçue par courriel du formateur. Les comptes Microsoft 365, Azure et Claude sont fournis.
- Un locataire Microsoft 365 de formation avec licence Microsoft Entra ID P1 (ou Business Premium), un abonnement Azure de formation.

## Votre poste : installer les outils et ouvrir le bon terminal

À faire avant le J1 (ou le J-1 avec le formateur). Ouvrez **Windows PowerShell** (menu Démarrer), pas en administrateur, et installez avec `winget` (les noms de paquets sont ceux de la fiche, section 9) :

```powershell
winget install Microsoft.PowerShell
winget install Git.Git
winget install Microsoft.VisualStudioCode
winget install OpenJS.NodeJS.LTS
winget install Microsoft.AzureCLI
winget install Hashicorp.Terraform
winget install GitHub.cli
winget install GLab.GLab
winget install jqlang.jq
```

**Git pour Windows n'est pas facultatif dans ce cours.** Il fournit Git Bash. Sous Windows, Claude Code lance les règles automatiques du dépôt (des scripts `.sh`) avec Git Bash ; sans Git Bash, il les lance avec PowerShell, et elles ne fonctionnent pas.

Puis **fermez toutes les fenêtres de terminal** et ouvrez **PowerShell 7** : menu Démarrer, « PowerShell 7 », ou tapez `pwsh` dans une fenêtre PowerShell. C'est le terminal de tout le cours.

```powershell
$PSVersionTable.PSVersion
git --version; gh --version; glab --version; az --version; terraform -version; node --version; jq --version
Install-Module Microsoft.Graph -Scope CurrentUser
```

**Vérifier** : la version de PowerShell commence par `7` ; chaque outil affiche un numéro. `Install-Module` demande si vous faites confiance au dépôt « PSGallery » : répondez `O` (ou `Y`). L'installation prend plusieurs minutes.

Pièges du terminal :

- **Windows PowerShell 5.1** (fenêtre bleue, `$PSVersionTable.PSVersion` commence par `5`) n'est pas PowerShell 7. Le script du LAB-03 refuse de tourner dans 5.1. Tapez `pwsh` pour passer à PowerShell 7.
- Un outil installé à l'instant n'est pas trouvé (« n'est pas reconnu ») : fermez et rouvrez le terminal. Une fenêtre ouverte avant l'installation ne voit pas le nouvel outil.
- Le terminal de l'**application Claude** : dans une session de l'onglet **Code**, cliquez **Terminal** dans la barre de titre de la session, ou appuyez sur **Ctrl+`**. Il s'ouvre dans le dossier de la session. Vérifiez qu'il s'agit de PowerShell 7 (`$PSVersionTable.PSVersion`) ; sinon, tapez `pwsh`.
- **Où mettre votre dépôt** : dans votre dossier personnel (`$HOME\lagune-ops`, par exemple `C:\Users\amina\lagune-ops`). Évitez un dossier synchronisé par OneDrive (souvent `Documents` ou `Bureau`).

**Préparé par le formateur avant la session** (les guides vous disent quand vous le vérifiez) : groupe `Lagune-Salaries` avec licence par groupe ; comptes d'urgence et groupe `Lagune-Urgence` ; rôle d'audit ; région et taille de VM autorisées par stratégie ; alerte de budget ; clé de la relecture automatique et application GitHub de Claude ; stockage de l'état Terraform ; identifiants fédérés (OpenID Connect) du dépôt de l'équipe et préfixe de l'équipe ; clé Anthropic plafonnée ; (l'équipe crée ensuite les environnements GitHub `plan`, `production` (relecteurs obligatoires) et `destruction`, les secrets et les variables, avec les identifiants remis par le formateur) ; adresse IP de la salle. **Préparé par l'équipe** : son propre nom de domaine et l'accès à sa zone DNS (voir le courriel d'avant-cours).

## Avant le J1 (formateur)

Une seule équipe de trois, une seule organisation. À faire avant le premier jour :

- [ ] Inviter chacun des trois participants au dépôt modèle, en lecture seule (une fois par `<LOGIN>`) :

```powershell
gh api -X PUT repos/Yolea-Hub/lagune-ops-starter/collaborators/<LOGIN> -f permission=pull
```

- [ ] Vérifier l'organisation : le formateur y est propriétaire (**Owner**) et le dépôt `<ORGANISATION>/lagune-ops` est **public**.
- [ ] Fixer le préfixe de l'équipe (`LAGUNE_PREFIX`, par exemple `lagune01`).
- [ ] Ajouter les identifiants fédérés (OpenID Connect) du dépôt de l'équipe dans le locataire de formation, avec le script du formateur du corrigé.
- [ ] Créer une clé Anthropic plafonnée pour l'équipe (secret de dépôt `ANTHROPIC_API_KEY`).
- [ ] Remettre à l'équipe ses identifiants (client, locataire, abonnement), son préfixe et sa clé, par un canal privé. Jamais dans le dépôt.

## Règles de sécurité

1. **Données fictives seulement** : `lagune.example`, adresses IP de documentation `203.0.113.x`, comptes inventés. Aucune donnée réelle, ni dans les dépôts, ni dans la conversation avec l'IA.
2. **Aucun secret** (mot de passe, jeton, clé) dans un dépôt, dans une capture, dans un journal ou dans la conversation avec Claude. Un secret se saisit dans votre terminal, masqué, ou dans le coffre de l'équipe.
3. **Le geste à la main d'abord. L'IA propose, vous décidez. Toujours une source.** Si vous ne pouvez pas expliquer une commande, vous ne la validez pas.
4. **Un plan lu avant toute approbation.** Pas de plan lu, pas d'approbation.
5. **Une branche, une demande de fusion, un deuxième regard.** Jamais de poussée directe sur `main`.
6. **Moindre privilège** : l'autorisation la plus petite qui suffit (Microsoft Graph, rôles, jetons).
7. **Ne jamais ouvrir un port à Internet** (3389 en particulier). On passe par Azure Bastion.
8. **Pas de suppression par Claude Code.** Les suppressions sont faites par un humain, après relecture. Les règles automatiques de l'espace de travail le bloquent.
9. **La boutique Juice Shop est volontairement vulnérable** : elle n'est jamais ouverte à tout Internet, seulement à l'adresse IP de la salle.
10. **Cadre légal** : les exercices d'intrusion visent uniquement votre propre boutique, avec l'accord écrit du formateur. Attaquer un système sans autorisation est un délit (loi ivoirienne n° 2013-451 du 19 juin 2013 relative à la lutte contre la cybercriminalité).
11. **Comptes d'urgence du formateur** : on les exclut des règles, on ne les utilise pas.

## Points ouverts communs

- **Rien n'a été exécuté dans un vrai locataire** : connexion OpenID Connect, déploiement réel, certificat géré, alerte de budget, import Graph réel, relecture par Claude, scan ZAP, pipeline GitLab, démonstration Ansible.
- **Décision du 7 novembre 2026 : un dépôt public, dans l'organisation gratuite de l'équipe.** Sur GitHub Free, Pro et Team, les relecteurs obligatoires d'un environnement n'existent que pour les dépôts publics : le dépôt `<ORGANISATION>/lagune-ops` est donc public (sans donnée réelle ni secret). Il reste à l'équipe après le cours. Variante privée : le miroir GitLab avec le bouton de déploiement manuel (LAB-07). Les approbations de déploiement GitLab demandent l'offre Premium ou Ultimate.
- **Bastion Developer** (gratuit, une VM à la fois) n'existe que dans certaines régions : à vérifier pour la région de formation.
- **La démonstration Ansible** cible la VM Windows du J3 par SSH : elle demande une préparation de la VM (OpenSSH) que le LAB-06 ne décrit pas.
- Plusieurs noms de menus des portails sont à confirmer sur le locataire.

## Nettoyage de fin de J4

À faire en fin de séance, dans cet ordre. **Chaque suppression est faite par un humain, après relecture.** Ne demandez pas à Claude Code de supprimer.

Le pipeline « Détruire la boutique » ne supprime **que** ce que Terraform a créé (la boutique). La VM du J3, son coffre de sauvegarde et le stockage de l'état Terraform se suppriment **à la main**.

### 1. Avant de commencer

- [ ] Plus personne n'est connecté à la VM par Bastion.
- [ ] Tous les rapports, captures et journaux des labs sont dans les dépôts (demandes de fusion fusionnées).

### 2. La boutique : le pipeline détruit les ressources Terraform

```powershell
gh workflow run destroy.yml -f confirmation=DETRUIRE
gh run list
gh run watch
```

Le pipeline « Détruire la boutique » lit aussi le plan de destruction. Lisez-le : seules les ressources de la boutique doivent y figurer.

- [ ] L'exécution est verte.
- [ ] `az group exists --name rg-<PREFIXE>-boutique` répond `false`.
- [ ] Si `DESTRUCTION_AUTO` vaut `oui`, la destruction automatique de 19 h passera ce soir : le formateur vérifie demain que l'exécution a réussi (onglet **Actions**).

Les enregistrements DNS (CNAME `boutique` et TXT `asuid.boutique`) ne sont **pas** supprimés par Terraform :

- [ ] Les deux enregistrements sont supprimés chez l'hébergeur du domaine.

### 3. La VM du J3 et son coffre : suppression à la main

**Ne verrouillez jamais l'immutabilité du coffre.** Le coffre doit rester « Disabled » (jamais « Enabled and locked »), sinon il ne pourra plus être supprimé avant l'expiration des sauvegardes.

Un coffre ne se supprime pas tant qu'il contient des sauvegardes. La suppression douce (14 jours par défaut) garde les sauvegardes supprimées pendant 14 jours et **bloque** la suppression du coffre. On la désactive donc avant de supprimer les sauvegardes.

Dans le portail Azure, coffre `rsv-<PREFIXE>` :

- [ ] **Properties**, **Security Settings** : désactiver **Soft Delete** (et les **Security Features** s'ils sont actifs).
- [ ] **Backup items**, **Azure Virtual Machine** : la machine, **Stop backup**, **Delete Backup Data**, taper le nom de la machine (sensible à la casse), valider.
- [ ] Vérifier qu'il ne reste aucun élément en « suppression douce » (si oui : le restaurer puis le supprimer à nouveau).
- [ ] Sur la page **Overview** du coffre : aucun élément de sauvegarde, aucun serveur. Puis **Delete** le coffre.

Puis le groupe de ressources de la VM (machine, disque, carte réseau, réseau virtuel, groupe de sécurité réseau, Bastion et son adresse IP s'il en reste) :

```powershell
az group delete --name rg-<PREFIXE>-vm
```

(Réponse `y` à la question. Commande lancée par un humain.)

- [ ] Le coffre est supprimé.
- [ ] `az group exists --name rg-<PREFIXE>-vm` répond `false`.
- [ ] Aucun Bastion Basic ni adresse IP publique ne reste (ils sont facturés à l'heure).

Si le coffre ne peut pas être supprimé aujourd'hui (suppression douce laissée active), il se supprimera après 14 jours : notez la date et laissez un propriétaire. Le groupe de ressources du coffre reste alors.

### 4. Le stockage de l'état Terraform (formateur)

À supprimer en **dernier**, après la fin de tous les pipelines, par le formateur :

- [ ] Groupe de ressources du compte de stockage de l'état (`TFSTATE_RESOURCE_GROUP`) supprimé.

### 5. Les restes éventuels

- [ ] Budgets, alertes et stratégies posés par le formateur sur l'abonnement : le formateur décide de les garder ou non.
- [ ] Ressources orphelines : disques, adresses IP publiques, interfaces réseau hors des groupes supprimés.
- [ ] Groupes créés automatiquement par Azure (par exemple celui de Network Watcher) : à noter, ils sont vides ou gérés par Azure.

### 6. Vérifier que tout est vide

```powershell
az group list --query "[].name" --output tsv | ForEach-Object { "$_ : " + (az resource list --resource-group $_ --query "length(@)" --output tsv) }
```

- [ ] Chaque groupe de ressources restant affiche `0`, ou est un groupe du formateur connu et voulu.
- [ ] Le portail Azure, **Cost Management**, ne montre aucune ressource qui tourne.

### 7. Microsoft 365 et Entra (formateur)

- [ ] Les 20 comptes fictifs et les règles d'accès conditionnel : le formateur décide de les garder ou de les supprimer. Un compte supprimé reste restaurable 30 jours.
- [ ] Les comptes d'urgence et le groupe `Lagune-Urgence` : au formateur.

### 8. Chaque participant, sur son poste

- [ ] Supprimer les fichiers de mots de passe temporaires (`lagune-mots-de-passe-*.csv`) et les CSV de travail du dossier temporaire.
- [ ] `Disconnect-MgGraph` et `az logout`.
- [ ] Retirer le serveur GitHub de Claude Code (dans le dossier `lagune-ops`, car il y a été ajouté : `Set-Location $HOME\lagune-ops`, puis `claude mcp remove github`) et **révoquer** le jeton GitHub créé au LAB-02 ; révoquer aussi le jeton GitLab s'il y en a un.
- [ ] Le dépôt reste : il est le portfolio de l'équipe.

### 9. Le formateur, après le cours

- [ ] Retirer les identifiants fédérés (OpenID Connect) du dépôt de l'équipe dans le locataire de formation.
- [ ] Révoquer la clé Anthropic plafonnée.
- [ ] Quitter l'organisation de l'équipe (le dépôt reste à l'équipe).

### 10. Le lendemain

- [ ] Ouvrir **Cost Management** dans le portail Azure : les coûts arrivent avec un retard d'un à deux jours. Aucun coût nouveau ne doit apparaître.

*Conception et animation : Yolea, Abidjan.*
