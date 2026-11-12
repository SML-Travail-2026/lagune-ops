# LAB-03 · Vingt salariés par une demande de fusion

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Ni la création réelle des comptes, ni la relecture par Claude dans GitHub, ni l'attribution de licence par groupe n'ont encore été essayées dans un vrai locataire.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J2, 13h30 |
| **Durée** | 90 minutes |
| **Brief vidéo** | J2-L03 (voir aussi J2-V05 et J2-V06) |

## Objectif

Faire arriver les vingt nouveaux salariés de Lagune à partir d'un fichier CSV, par un script relu. Le script passe d'abord par une demande de fusion, relue par Claude puis par un coéquipier. Il est essayé en mode essai, puis sur 2 comptes, puis sur les 20.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Dev** | Prépare la branche, ouvre la demande de fusion, répond aux commentaires. Peut demander à Claude Code d'expliquer le script. |
| **Ops** | Lance le mode essai, puis 2 comptes, puis les 20. Vérifie les comptes dans le portail. |
| **Sécurité** | Vérifie les autorisations demandées et l'absence de mot de passe en clair. Approuve la demande de fusion. |

## Prérequis

- LAB-01 et LAB-02 terminés. Tout ce lab se fait dans **PowerShell 7**, dans votre dossier `lagune-ops` (`Set-Location $HOME\lagune-ops`) : `$PSVersionTable.PSVersion` commence par `7`. Le script commence par `#Requires -Version 7.2` : dans Windows PowerShell 5.1, il refuse de démarrer. Tapez `pwsh` si besoin.
- Si PowerShell répond que « l'exécution de scripts est désactivée sur ce système », autorisez-la pour cette fenêtre seulement : `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`. Ce réglage disparaît quand vous fermez la fenêtre.
- Module Microsoft Graph PowerShell : `Get-Module -ListAvailable Microsoft.Graph*` n'est pas vide. Sinon : `Install-Module Microsoft.Graph -Scope CurrentUser` (répondez `O` à la question sur « PSGallery » ; comptez plusieurs minutes).
- Un compte qui a au moins le rôle **Administrateur des utilisateurs** dans votre locataire de formation.
- **Préparé par le formateur** :
  - un groupe de sécurité `Lagune-Salaries`, avec la licence attribuée **par groupe** ;
  - le nom de domaine de votre locataire de formation (par exemple `<DOMAINE_LOCATAIRE>`, de la forme `nom.onmicrosoft.com`) ;
  - la clé de la relecture automatique (secret `ANTHROPIC_API_KEY`) : une clé Anthropic **plafonnée, pour l'équipe**, remise par le formateur (jamais dans le dépôt public) ; et l'application GitHub de Claude, installée sur votre dépôt.
- Le script, le CSV et le fichier de relecture sont déjà dans votre dépôt, dans `kit/lab-03/` (écrits par le formateur) : vous les déplacez à leur place.

> **Important : le domaine.** Le fichier CSV utilise le domaine fictif `lagune.example`. Il ne peut pas exister dans un vrai locataire. Pour la création réelle, on utilise une **copie locale** du CSV avec le domaine de votre locataire. Le CSV de la demande de fusion reste fictif.

## Étapes

### 1. Ajouter d'abord la relecture automatique

Le fichier de relecture doit être dans `main` **avant** la demande de fusion qui sera relue. C'est une précaution : certaines actions GitHub refusent de tourner si leur fichier n'existe pas encore sur la branche principale. Ce comportement n'a pas été vérifié ici.

Enregistrez la clé que le formateur vous a remise dans les secrets du dépôt (un seul membre de l'équipe le fait). La commande vous demande la valeur, masquée. Ne la collez jamais dans la conversation :

```powershell
gh secret set ANTHROPIC_API_KEY
```

Petite demande de fusion pour le fichier de relecture :

```powershell
git switch main
git pull
git switch -c ci/relecture-claude
New-Item -ItemType Directory -Force .github\workflows | Out-Null
git mv kit\lab-03\.github\workflows\claude-review.yml .github\workflows\claude-review.yml
git add .github/workflows/claude-review.yml
git commit -m "Ajoute la relecture automatique par Claude"
git push -u origin ci/relecture-claude
gh pr create --title "Ajoute la relecture automatique par Claude" --body "Claude commente les demandes qui touchent data/ ou scripts/."
```

Un coéquipier relit sur son poste, avec le numéro de la demande (`gh pr list`, `gh pr diff <NUMERO>`, `gh pr review <NUMERO> --approve`), puis l'auteur, sur sa branche, fusionne : `gh pr merge --merge --delete-branch`.

**Vérifier** : le fichier `.github/workflows/claude-review.yml` est dans `main`. Il dit que la relecture a lieu sur les chemins `data/**` et `scripts/**`.

### 2. Ajouter le CSV et le script sur une branche (rôle Dev)

```powershell
git switch main
git pull
git switch -c feat/import-salaries
New-Item -ItemType Directory -Force data, scripts | Out-Null
git mv kit\lab-03\data\salaries-lagune.csv data\salaries-lagune.csv
git mv kit\lab-03\scripts\Import-LaguneUsers.ps1 scripts\Import-LaguneUsers.ps1
```

Demandez à Claude Code d'expliquer le script **avant** de l'envoyer :

```text
Explique-moi scripts/Import-LaguneUsers.ps1 étape par étape, en français simple.
Quelles autorisations demande-t-il ? Où va le mot de passe temporaire ?
```

Notez les réponses. Vous devez pouvoir dire :

- les trois autorisations : `User.Create`, `User.ReadBasic.All`, `GroupMember.ReadWrite.All` ;
- sans `-Apply`, rien n'est créé et aucune connexion n'est faite ;
- les mots de passe vont dans un fichier hors du dépôt, jamais à l'écran.

**Vérifier** : le CSV a 21 lignes (un en-tête et 20 salariés) :

```powershell
(Get-Content data\salaries-lagune.csv).Count
```

### 3. L'essai à blanc (rôle Ops)

Aucune connexion, rien n'est créé. La branche n'est pas encore envoyée : l'essai se fait **sur le poste du Dev**, dans `lagune-ops`.

```powershell
./scripts/Import-LaguneUsers.ps1 -CsvPath ./data/salaries-lagune.csv
```

**Vérifier** : le script affiche « Fichier valide : 20 salarié(s) à traiter. », puis 20 lignes qui commencent par `[ESSAI]`, puis « Essai à blanc terminé ».

Provoquez une erreur exprès, sur une copie hors du dépôt :

```powershell
$test = Join-Path $env:TEMP "test-erreur.csv"
(Get-Content .\data\salaries-lagune.csv -Encoding utf8) -replace 'mamadou\.traore@', 'mamadou.traoré@' | Set-Content -Path $test -Encoding utf8
./scripts/Import-LaguneUsers.ps1 -CsvPath $test
```

Le script doit refuser (UPN avec accent) et dire « rien n'a été fait ». Un nom d'utilisateur ne doit pas avoir d'accent.

### 4. La demande de fusion (rôle Dev)

```powershell
git add data/salaries-lagune.csv scripts/Import-LaguneUsers.ps1
git commit -m "Ajoute le CSV des 20 salariés et le script d'import"
git push -u origin feat/import-salaries
gh pr create --title "Import des 20 salariés de Lagune" --body "CSV fictif (lagune.example) et script Microsoft Graph PowerShell. Essai à blanc par défaut, -Apply -First 2 pour un essai réel."
```

**Vérifier** : sur la page de la demande, l'onglet **Checks** (ou **Actions**) montre l'exécution « Relecture par Claude ». Au bout de quelques minutes, Claude laisse un avis et peut-être des commentaires sur des lignes.

### 5. Lire la relecture de Claude, puis celle du coéquipier (rôles Dev et Sécurité)

1. Lisez chaque commentaire de Claude. Pour chacun, décidez : juste (vous corrigez) ou faux (vous répondez, avec une raison).
2. Claude **commente**, il ne décide pas. Son avis ne remplace pas celui d'un humain.
3. Le rôle **Sécurité** relit avec cette liste :
   - [ ] Microsoft Graph PowerShell seulement (ni MSOnline, ni AzureAD) ;
   - [ ] trois autorisations, pas plus ;
   - [ ] essai à blanc par défaut ;
   - [ ] aucun mot de passe écrit dans le script ou le CSV ;
   - [ ] aucune donnée réelle dans le CSV.
4. Le coéquipier approuve, sur son poste, avec le numéro de la demande :

```powershell
gh pr list
gh pr view <NUMERO>
gh pr diff <NUMERO>
gh pr review <NUMERO> --approve --body "Relu : autorisations minimales, essai à blanc par défaut."
```

Puis l'auteur (rôle Dev), sur sa branche, fusionne :

```powershell
gh pr merge --merge --delete-branch
git switch main
git pull
```

**Vérifier** : la demande est fusionnée. Elle a un avis de Claude **et** une approbation humaine.

### 6. Préparer le CSV pour votre locataire (rôle Ops)

Sur le poste du rôle Ops, à jour de `main` (après la fusion), copie locale hors du dépôt :

```powershell
Set-Location $HOME\lagune-ops
git switch main
git pull
$domaine = "<DOMAINE_LOCATAIRE>"
$csv = Join-Path $env:TEMP "salaries-locataire.csv"
(Get-Content .\data\salaries-lagune.csv -Encoding utf8) -replace '@lagune\.example', "@$domaine" | Set-Content -Path $csv -Encoding utf8
```

**Vérifier** : `Get-Content $csv -TotalCount 3` montre des adresses qui finissent par votre domaine.

### 7. Deux comptes d'abord (rôle Ops)

```powershell
./scripts/Import-LaguneUsers.ps1 -CsvPath $csv -Domain $domaine -Apply -First 2
```

Une fenêtre de connexion s'ouvre. Elle liste les autorisations demandées : **lisez-la**. Elle doit correspondre aux trois autorisations de l'étape 2. Connectez-vous avec votre compte d'administration.

Le script écrit les mots de passe temporaires dans un fichier de votre dossier personnel, dont il affiche le nom. Il ne les affiche pas à l'écran.

**Vérifier**, dans le centre d'administration Microsoft 365 ou Entra, **Utilisateurs** :

- les 2 comptes existent (Aya Kouassi, Koffi Yao) ;
- ils sont membres du groupe `Lagune-Salaries` ;
- ils ont leur licence (l'attribution par groupe peut prendre quelques minutes : actualisez) ;
- leur pays d'utilisation est `CI`.

Option de prudence : `-Apply -WhatIf` se connecte vraiment mais annonce chaque création sans la faire.

Si un compte est créé mais absent du groupe, le groupe vient peut-être d'être créé : un délai de réplication est possible. Attendez quelques minutes avant de relancer.

### 8. Les vingt (rôle Ops)

```powershell
./scripts/Import-LaguneUsers.ps1 -CsvPath $csv -Domain $domaine -Apply
```

Les 2 comptes déjà créés sont ignorés (`[IGNORÉ]`). Les 18 autres sont créés.

**Vérifier** : le groupe `Lagune-Salaries` contient 20 membres. Les 20 ont une licence. Aucun mot de passe n'est apparu à l'écran.

### 9. Ranger

Le fichier des mots de passe temporaires ne se lit pas dans la conversation avec Claude, ne se commite jamais. Dans cet exercice, les comptes sont fictifs. Supprimez le fichier vous-même (Claude n'a pas le droit de supprimer) :

```powershell
Remove-Item -Path $csv
Remove-Item -Path (Join-Path $HOME "lagune-mots-de-passe-*.csv")
```

## Pièges

- **Lancer les vingt d'un coup.** Mode essai, puis deux comptes, puis les vingt.
- **Un nom d'utilisateur avec accent ou espace.** Le script le refuse, c'est voulu.
- **Le domaine fictif.** `lagune.example` n'existe pas dans votre locataire : utilisez le domaine du formateur pour la création réelle.
- **Une licence qui tarde.** L'attribution par groupe n'est pas instantanée. Ne recréez pas le compte.
- **Un groupe qui vient d'être créé.** Le délai de réplication peut faire échouer l'ajout d'un membre. Attendez et relancez : les comptes existants sont ignorés.
- **Un mot de passe dans le dépôt, dans une capture ou dans la conversation.** Jamais.
- **Prendre l'avis de Claude pour une approbation.** Il faut un humain.

## Livrable

- La demande de fusion « Import des 20 salariés de Lagune », relue par Claude et par un coéquipier, fusionnée.
- Les 20 comptes créés, membres de `Lagune-Salaries`, avec leur licence.
- Une courte note dans `docs/` (rédigée par le rôle Dev, validée par le rôle Sécurité) : ce que Claude a signalé, ce que vous avez corrigé, ce que vous avez refusé et pourquoi.

## Points ouverts

- La licence requise pour l'attribution de licences par groupe n'est pas indiquée sur la page Microsoft (voir `17_Videos_Jours/sources.md`, ligne M8). Le formateur la confirme sur le locataire.
- La relecture par Claude exige un secret et l'installation de l'application GitHub de Claude. Ils sont préparés par le formateur et n'ont pas été essayés.
- La règle « le fichier de relecture doit déjà être dans `main` » est une précaution non vérifiée.
- Sur un dépôt privé, les contrôles de fusion obligatoires dépendent du plan GitHub (voir LAB-01).

## Sources

- https://learn.microsoft.com/en-us/graph/api/user-post-users (`User.Create`, propriétés requises, `New-MgUser`)
- https://learn.microsoft.com/en-us/graph/api/group-post-members (`GroupMember.ReadWrite.All`, `New-MgGroupMemberByRef`, délai de réplication)
- https://learn.microsoft.com/en-us/powershell/microsoftgraph (Connect-MgGraph)
- https://learn.microsoft.com/en-us/microsoft-365/admin/manage/manage-group-licenses
- https://github.com/anthropics/claude-code-action/blob/v1/docs/solutions.md
- https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- `17_Videos_Jours/sources.md`, lignes M1, M2, M8, G9 ; dépôt modèle, dossier `kit/lab-03/` (`scripts/Import-LaguneUsers.ps1`, `data/salaries-lagune.csv`, `.github/workflows/claude-review.yml`)

*Conception et animation : Yolea, Abidjan.*
