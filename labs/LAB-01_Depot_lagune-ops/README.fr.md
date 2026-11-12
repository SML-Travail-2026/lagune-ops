# LAB-01 · Le dépôt lagune-ops et son miroir

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Ce guide n'a pas encore été essayé dans un vrai locataire ni sur de vrais comptes GitHub et GitLab.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J1, 13h30 (séance Git, GitHub, GitLab) |
| **Durée** | 60 minutes |
| **Brief vidéo** | J1-L01 |

## Objectif

Créer le dépôt de l'équipe, `lagune-ops`, sur GitHub, puis son miroir sur GitLab. Faire respecter la règle « rien n'entre sans un deuxième regard ». Écrire la carte de l'environnement.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Dev** | Crée le dépôt et la première branche. Ouvre la première demande de fusion. |
| **Ops** | Écrit la carte de l'environnement : locataire, abonnement, groupe de ressources, les trois portails. |
| **Sécurité** | Active la règle d'une relecture obligatoire. Relit la demande de fusion. Vérifie qu'aucun secret n'y figure. |

Les rôles tournent chaque jour. Notez qui tient quel rôle aujourd'hui.

## Prérequis

- Votre poste est prêt (voir « Votre poste » dans [le guide général](../README.fr.md)) : vous travaillez dans **PowerShell 7** (`$PSVersionTable.PSVersion` commence par `7`), et `git --version`, `gh --version`, `glab --version`, `az --version` répondent.
- Un compte GitHub et un compte GitLab (gratuits).
- L'invitation GitHub au dépôt `Yolea-Hub/lagune-ops-starter`, reçue par courriel du formateur : **chacun** de l'équipe l'accepte avant le lab (sans elle, la commande de l'étape 2 échoue).
- Votre équipe de trois : le **chef d'équipe** crée l'organisation GitHub gratuite de l'équipe (étape 1). Les deux autres ont aussi un compte GitHub : ils relisent vos demandes de fusion.
- Un abonnement Azure et un locataire Microsoft 365 de formation, fournis par le formateur.

## Étapes

### 1. Créer l'organisation GitHub de l'équipe (chef d'équipe, avant le J1)

L'équipe travaille dans **sa propre organisation GitHub gratuite**, pas dans un compte personnel. Le chef d'équipe la crée, de préférence avant le J1 :

1. Sur GitHub : **+** (en haut à droite), **New organization**, puis l'offre **Free**.
2. Nom : au choix du chef d'équipe, par exemple `lagune-ops-<SESSION>` (`<SESSION>` : le mois de la session, par exemple `nov2026`). Ce nom remplace `<ORGANISATION>` dans tout le cours.
3. Invitez les deux coéquipiers comme **membres** (étape 4) et le formateur comme **propriétaire** (**Owner**) : **People**, **Invite member**, avec le compte `<COMPTE_FORMATEUR>` donné par le formateur.

**Vérifier** : la page `https://github.com/orgs/<ORGANISATION>/people` liste le formateur (rôle Owner) et vos coéquipiers (ou leur invitation en attente).

### 2. Se connecter à GitHub

```powershell
gh auth login
gh auth status
git config --global user.name "Votre Nom"
git config --global user.email "votre.adresse@exemple.invalid"
```

`gh auth login` pose quelques questions : choisissez **GitHub.com**, le protocole **HTTPS**, répondez **Yes** à « Authenticate Git with your GitHub credentials? », puis **Login with a web browser** (un code s'affiche, à saisir dans la page qui s'ouvre).

**Vérifier** : `gh auth status` indique que vous êtes connecté à `github.com`. Aucun mot de passe n'est écrit dans un fichier.

### 3. Créer le dépôt (rôle Dev)

Le formateur a préparé un dépôt modèle, `Yolea-Hub/lagune-ops-starter`. Le chef d'équipe en crée la copie de l'équipe, **dans l'organisation** et publique : elle contient déjà le fichier `CLAUDE.md`, le dossier `.claude/`, un `.gitignore` complet (il empêche d'envoyer par erreur un secret ou un état Terraform) et le dossier `kit/`, qui servira aux labs suivants.

La commande clone le dépôt dans le dossier où vous êtes. Placez-vous d'abord dans votre dossier personnel (pas dans un dossier OneDrive) :

```powershell
Set-Location $HOME
gh repo create <ORGANISATION>/lagune-ops --template Yolea-Hub/lagune-ops-starter --public --clone
Set-Location lagune-ops
```

Le dépôt est maintenant dans `$HOME\lagune-ops` (par exemple `C:\Users\amina\lagune-ops`). Les labs suivants partent de ce dossier : `Set-Location $HOME\lagune-ops`.

> **Pourquoi un dépôt public ?** Les relecteurs obligatoires des environnements GitHub (utilisés au LAB-07) n'existent, sur GitHub Free, Pro et Team, que pour les dépôts **publics**. Votre dépôt est donc public : il ne contient jamais aucune donnée réelle ni aucun secret (les règles de `.claude/` et le `.gitignore` y veillent). Le dépôt reste celui de l'équipe après le cours (votre portfolio) ; le formateur retire les accès Azure et révoque les clés.

**Vérifier** :

```powershell
gh repo view --web
git remote -v
```

La page GitHub s'ouvre. Le dépôt est dans l'organisation `<ORGANISATION>` et marqué **Public**. `git remote -v` montre `origin`.

```powershell
Get-Item CLAUDE.md, kit
```

Les deux existent : le dépôt contient bien `CLAUDE.md` et le dossier `kit/`.

### 4. Inviter les coéquipiers dans l'organisation (rôle Dev)

Les coéquipiers sont **membres de l'organisation** : ils n'ont pas besoin d'être invités sur le dépôt. Pour chacun :

```powershell
gh api -X PUT orgs/<ORGANISATION>/memberships/<COMPTE_DU_COEQUIPIER> -f role=member
```

Autre voie : sur GitHub, dans l'organisation, **People**, puis **Invite member**. Le coéquipier accepte l'invitation reçue par courriel, puis clone le dépôt :

```powershell
Set-Location $HOME
gh repo clone <ORGANISATION>/lagune-ops
Set-Location lagune-ops
```

**Vérifier** : le coéquipier apparaît dans **People** de l'organisation, ouvre le dépôt dans son navigateur sans erreur 404, et le dossier `lagune-ops` existe sur son poste après le clonage.

### 5. Imposer une relecture avant toute fusion (rôle Sécurité)

Dans le dépôt, sur GitHub : **Settings**, **Branches** (ou **Rules**, **Rulesets**), puis créez une règle pour la branche `main` :

- exiger une demande de fusion avant la fusion ;
- exiger **1** approbation.

Les noms exacts des cases peuvent changer : lisez l'écran et prenez la case qui dit « exiger une approbation ».

**Vérifier** : essayez de pousser directement sur `main`.

```powershell
Add-Content -Path README.fr.md -Value "test direct"
git commit -am "Essai de poussée directe"
git push origin main
```

GitHub doit **refuser**. Annulez ensuite votre essai (c'est un geste humain, pas pour Claude) :

```powershell
git reset --hard origin/main
```

Si, au contraire, GitHub **a accepté** la poussée (la règle n'est pas appliquée : par exemple si le dépôt n'est pas public), votre essai est déjà sur `main` : `git reset --hard` ne l'enlève pas. Défaites-le sans rien perdre, avec un nouveau commit :

```powershell
git revert HEAD
git push
```

Notez dans la carte de l'environnement que la règle n'est pas appliquée, et prévenez le formateur.

> **Limite connue.** Sur un dépôt **privé**, cette règle peut demander un compte payant (GitHub Team ou Pro). Si vous ne trouvez pas la règle, ou si GitHub accepte la poussée directe, **notez-le** et prévenez le formateur. La règle de l'équipe reste valable : vous ne poussez jamais sur `main`. Mais ce n'est plus GitHub qui l'impose.

### 6. Écrire la carte de l'environnement (rôle Ops)

On travaille toujours sur une branche.

```powershell
git switch -c docs/carte-environnement
New-Item -ItemType Directory -Force docs | Out-Null
```

Pour lire les noms de votre abonnement (sans rien modifier) :

```powershell
az login
az account show --query "{abonnement:name, locataire:tenantId}" --output table
```

Créez le fichier `docs/carte-environnement.md` avec ce plan, dans Visual Studio Code (`code docs\carte-environnement.md`, puis enregistrez avec Ctrl+S). Écrivez les **noms**, pas les identifiants longs :

```markdown
# Carte de l'environnement Lagune

| Élément | Valeur | Où le voir |
|---|---|---|
| Locataire (tenant) | <NOM_DU_LOCATAIRE> | Centre d'administration Entra |
| Abonnement (subscription) | <NOM_DE_L_ABONNEMENT> | Portail Azure, Abonnements |
| Groupe de ressources (resource group) | rg-<PREFIXE>-vm (créé au LAB-06) | Portail Azure |
| Région | <REGION_DE_FORMATION> | Donnée par le formateur |

## Les trois portails

| Portail | Adresse | Pour quoi faire |
|---|---|---|
| Centre d'administration Microsoft 365 | https://admin.microsoft.com | Comptes, licences, groupes |
| Centre d'administration Microsoft Entra | https://entra.microsoft.com | Identités, accès conditionnel, rôles |
| Portail Azure | https://portal.azure.com | Machines, réseaux, sauvegardes |

## Règles
- Aucun identifiant long (GUID), aucun mot de passe dans ce dépôt.
- Les valeurs réelles sont dans le coffre de mots de passe de l'équipe.
```

**Vérifier** : relisez le fichier. Il ne contient ni mot de passe, ni identifiant long, ni clé.

### 7. Première demande de fusion

```powershell
git add docs/carte-environnement.md
git commit -m "Ajoute la carte de l'environnement"
git push -u origin docs/carte-environnement
gh pr create --title "Ajoute la carte de l'environnement" --body "Première carte : locataire, abonnement, groupe de ressources, trois portails."
```

Le rôle **Sécurité** (ou le coéquipier invité) relit, **sur son propre poste**. Il est sur `main`, pas sur la branche de la demande : il donne donc le numéro de la demande (`gh pr list` l'affiche, par exemple `1`).

```powershell
Set-Location $HOME\lagune-ops
gh pr list
gh pr view <NUMERO>
gh pr diff <NUMERO>
gh pr review <NUMERO> --approve --body "Relu : aucun secret."
```

Une personne qui a ouvert la demande ne peut pas l'approuver elle-même. C'est le but.

Puis l'auteur de la demande (rôle Dev), toujours sur sa branche, fusionne :

```powershell
gh pr merge --merge --delete-branch
git switch main
git pull
```

**Vérifier** : `git log --oneline` montre le commit de la carte sur `main`. La demande de fusion est marquée **Merged** sur GitHub.

### 8. Le miroir GitLab

1. Sur GitLab, créez un projet **vide** : **New project**, puis **Create blank project**. Nom : `lagune-ops`. Niveau : **Private**. **Décochez** la case qui crée un fichier README. Un projet qui contient déjà un fichier refuse votre première poussée.
2. Connectez `glab`, puis ajoutez GitLab comme deuxième destination :

```powershell
glab auth login
git remote add gitlab https://gitlab.com/<COMPTE_GITLAB>/lagune-ops.git
git push gitlab main
```

Si GitLab demande un mot de passe, utilisez un jeton d'accès personnel que **vous** créez dans votre profil GitLab, avec le droit `write_repository`, et collez-le à l'invite. Ne l'écrivez jamais dans une commande ni dans un fichier.

**Vérifier** : la page du projet GitLab montre `README.fr.md`, `CLAUDE.md`, `kit` et le dossier `docs`. L'historique est le même que sur GitHub.

À partir de maintenant, après chaque fusion :

```powershell
git switch main
git pull
git push gitlab main
```

La copie ne se fait pas toute seule.

## Pièges

- **Travailler directement sur `main`.** Créez toujours une branche, même pour une seule ligne.
- **Un projet GitLab non vide.** Il faut un projet vide, sans README, sinon `git push gitlab main` est refusé.
- **Oublier de pousser vers GitLab.** Les deux plateformes divergent. Poussez les deux.
- **Un secret dans le dépôt.** Même supprimé plus tard, il reste dans l'historique. Si cela arrive, prévenez le formateur : le secret doit être remplacé.
- **Approuver sa propre demande.** GitHub l'interdit. Demandez à un coéquipier.
- **Le nom de la branche principale.** Le dépôt de départ utilise `main`. Si `git branch` montre autre chose, prévenez le formateur.

## Livrable

- Le dépôt public `<ORGANISATION>/lagune-ops` sur GitHub, dans l'organisation gratuite de l'équipe, avec la règle d'une relecture obligatoire (ou la note qui dit pourquoi elle n'a pas pu être activée).
- La première demande de fusion, relue par un coéquipier et fusionnée.
- Le miroir GitLab, avec le même historique.
- Le fichier `docs/carte-environnement.md` dans `main`.

## Points ouverts

- Les relecteurs obligatoires d'un environnement GitHub n'existent que pour les dépôts publics (offres Free, Pro et Team) : c'est pourquoi le dépôt de formation est public, dans l'organisation de l'équipe. Après le cours, il reste à l'équipe (portfolio) ; le formateur retire les accès Azure et révoque les clés. Sur GitLab, les approbations de fusion demandent l'offre Premium : sur le miroir, la règle reste une règle d'équipe.
- Les noms des cases dans les écrans GitHub et GitLab changent souvent. Les captures du formateur font foi.
- La commande `gh api -X PUT orgs/.../memberships/...` a été relue sur la page de référence de l'API REST GitHub (point d'accès « Set organization membership for a user », paramètre `role` : `member` ou `admin`) ; elle envoie une invitation par courriel à un compte qui n'est pas encore membre. Elle demande d'être propriétaire de l'organisation. Le chemin par l'interface fonctionne dans tous les cas.
- Les étapes de l'organisation et du dépôt n'ont pas été essayées sur de vrais comptes GitHub.

## Sources

- https://cli.github.com/manual/gh_repo_create (options `--template`, `--public`, `--clone`)
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/creating-a-new-organization-from-scratch (créer une organisation)
- https://docs.github.com/en/rest/orgs/members#set-organization-membership-for-a-user (inviter un membre)
- https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment (relecteurs obligatoires : dépôts publics sur Free, Pro et Team)
- https://git-scm.com/docs/git-remote
- https://docs.gitlab.com/ci/environments/deployment_approvals/ (approbations : Premium et Ultimate)
- `17_Videos_Jours/sources.md`, ligne G10

*Conception et animation : Yolea, Abidjan.*
