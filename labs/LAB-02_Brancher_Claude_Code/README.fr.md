# LAB-02 · Brancher Claude Code à vos outils

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Ce guide n'a pas encore été essayé dans un vrai locataire. Le branchement GitLab et les règles automatiques sont les points les plus fragiles.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J1, 15h15 (séance Claude Code) |
| **Durée** | 45 minutes |
| **Brief vidéo** | J1-L02 (voir aussi J1-V09 et J1-V10) |

## Objectif

Brancher votre Claude Code à Microsoft Learn, Azure, GitHub et GitLab. Vérifier que les règles automatiques de l'espace de travail bloquent une suppression. Puis prendre l'IA en défaut : trouver au moins une erreur et la corriger.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Dev** | Ajoute les serveurs MCP et vérifie qu'ils répondent. Tient le journal de la chasse aux hallucinations. |
| **Ops** | Pose trois questions sur Azure à Claude Code et note la source citée pour chacune. |
| **Sécurité** | Vérifie les permissions et les règles automatiques de l'espace de travail. Tente une suppression : elle doit être bloquée. |

Un serveur MCP est une prise standard qui relie une IA à un outil. Chacun branche **son** Claude Code : les trois rôles travaillent en parallèle, puis comparent.

## Prérequis

- LAB-01 terminé : vous avez le dépôt `lagune-ops` sur votre poste.
- Node.js LTS : `node --version` affiche un numéro.
- Azure CLI connecté : voir l'étape 1.
- Claude Code installé et connecté, application **et** commande `claude` : voir l'étape 0.
- L'espace de travail préparé : les fichiers `CLAUDE.md` et `.claude/` sont déjà à la racine de votre dépôt (ils viennent du dépôt modèle).
- **`jq` installé.** Les règles automatiques en ont besoin. Voir l'étape 7.

## Étapes

### 0. Installer Claude Code et se connecter (tout le monde, avant le lab)

Chaque poste Windows a **deux** façons d'utiliser Claude Code, avec le **même** compte Claude (fourni par le formateur) :

- **l'application Claude** (onglet **Code**) : pour travailler au quotidien, dans une fenêtre ;
- **la commande `claude`** dans PowerShell : ce lab en a besoin pour `claude mcp add` et `claude mcp list`. L'application **n'installe pas** cette commande.

**0a. L'application Claude**

1. Téléchargez l'installateur Windows sur https://claude.com/download, lancez-le (pas besoin d'être administrateur).
2. Ouvrez **Claude** depuis le menu Démarrer et connectez-vous avec votre compte Claude de formation.
3. Cliquez sur l'onglet **Code** en haut de la barre latérale (survolez les icônes pour voir leur nom).
4. Sous la zone de saisie, choisissez l'environnement **Local**, puis le contrôle de dossier, **Open folder…**, et ouvrez votre dossier `lagune-ops` (`C:\Users\<vous>\lagune-ops`).
5. Repérez le **terminal** de l'application : bouton **Terminal** dans la barre de titre de la session, ou **Ctrl+`**. Il s'ouvre dans le dossier `lagune-ops`. Tapez `$PSVersionTable.PSVersion` : si le numéro commence par `5`, tapez `pwsh` pour passer à PowerShell 7. Toutes les commandes PowerShell de ce lab peuvent se taper ici, ou dans une fenêtre PowerShell 7 séparée.

**Vérifier** : demandez « Résume le fichier README de ce dépôt. » Claude répond à partir de votre dépôt. Un message vous demande de prendre un abonnement payant : prévenez le formateur (le plan gratuit n'inclut pas Claude Code).

**0b. La commande `claude`**

Prérequis : Git pour Windows (https://git-scm.com/downloads/win, ou `winget install Git.Git`). Il fournit Git Bash. **Il est obligatoire dans ce cours** : sous Windows, Claude Code lance les règles automatiques (hooks) avec Git Bash, et avec PowerShell quand Git Bash est absent ; les règles de l'étape 7 sont des scripts bash, qui ne tournent pas sous PowerShell.

Dans PowerShell (pas en administrateur ; le terminal de l'application convient) :

```powershell
irm https://claude.ai/install.ps1 | iex
```

Fermez et rouvrez le terminal (une fenêtre ouverte avant l'installation ne trouve pas `claude`), puis :

```powershell
claude --version
Set-Location $HOME\lagune-ops
claude
```

Au premier lancement, `claude` ouvre le navigateur : connectez-vous avec **le même** compte Claude. Si le navigateur ne s'ouvre pas, appuyez sur `c` pour copier l'adresse de connexion. Le terminal affiche `Login successful` : appuyez sur Entrée. Pour vous reconnecter plus tard : tapez `/login` dans Claude Code.

Claude Code vous demande ensuite si vous faites confiance à ce dossier : **acceptez** (vous êtes dans votre dépôt `lagune-ops`). Sans cet accord, Claude Code ignore les autorisations (`allow`) du fichier `.claude/settings.json` ; les règles `deny` et `ask` restent actives. Il vous demanderait une permission à chaque commande. L'accord vaut pour tout le dépôt et il est enregistré dans votre profil. Faites-le **une fois ici, dans le terminal** : la documentation de l'application ne dit pas si l'onglet **Code** pose lui-même cette question.

**Vérifier** : `claude --version` affiche un numéro. `claude doctor` ne signale pas d'erreur bloquante.

Les serveurs ajoutés par `claude mcp add` (étapes 2, 4, 5) sont enregistrés dans votre profil (`$HOME\.claude.json`), que l'application lit aussi. Sans option `-s user`, un serveur n'est ajouté que pour le dossier où vous tapez la commande : tapez-les dans `lagune-ops`. Après les étapes 2 à 5, rouvrez une session dans l'onglet **Code** et vérifiez que les mêmes outils y répondent. Dans l'application, les plugins (étape 3) s'ajoutent aussi par le bouton **+**, puis **Add plugins**. Les commandes à panneau (`/mcp`, `/plugin`) peuvent répondre « isn't available in this environment » dans l'onglet **Code** : tapez-les alors dans `claude`, au terminal.

### 1. Se connecter à Azure

```powershell
az login
az account show
```

**Vérifier** : `az account show` affiche votre abonnement de formation (nom et état « Enabled »).

### 2. Brancher Microsoft Learn (rôle Dev)

Ce serveur est gratuit et ne demande aucun compte.

```powershell
claude mcp add --transport http microsoft-learn https://learn.microsoft.com/api/mcp
```

**Vérifier** : voir l'étape 6 pour la liste. Le serveur `microsoft-learn` doit apparaître.

### 3. Brancher Azure avec l'extension Azure Skills (rôle Dev)

Prérequis : Node.js LTS et la connexion `az login` faite à l'étape 1.

Lancez `claude` dans le terminal, depuis votre dossier `lagune-ops` (`Set-Location $HOME\lagune-ops`, puis `claude`), puis tapez, dans la conversation :

```text
/plugin marketplace add microsoft/azure-skills
/plugin install azure@azure-skills
/plugin list
```

Redémarrez Claude Code si le plugin n'apparaît pas (`/exit`, puis `claude`). Quittez ensuite `claude` avec `/exit` pour revenir à PowerShell.

**Vérifier** : `/plugin list` montre `azure@azure-skills`. Demandez ensuite en français : « Liste mes abonnements Azure. » Claude Code doit afficher votre abonnement de formation.

### 4. Brancher GitHub (rôle Dev)

Le serveur GitHub demande un jeton d'accès. **Vous** le créez, pas Claude Code.

1. Sur GitHub : **Settings**, **Developer settings**, **Personal access tokens**, **Fine-grained tokens**. Créez un jeton limité au seul dépôt `lagune-ops`, avec la durée la plus courte (une semaine), en lecture des dépôts, des tickets et des demandes de fusion. Le formateur vous dit si l'écriture est autorisée.
2. Dans **votre** terminal PowerShell (pas dans la conversation Claude), saisissez-le sans l'afficher, puis branchez le serveur :

```powershell
$saisie = Read-Host -Prompt "Jeton GitHub" -AsSecureString
$env:GITHUB_PAT = [System.Net.NetworkCredential]::new("", $saisie).Password
claude mcp add --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer $env:GITHUB_PAT"
Remove-Item Env:GITHUB_PAT
Remove-Variable saisie
```

Cette forme marche dans PowerShell 7 et dans Windows PowerShell 5.1 (l'option `-MaskInput` n'existe que depuis PowerShell 7.1). Tapez ces lignes dans PowerShell, **pas** dans `claude`.

macOS ou Linux (bash ou zsh) :

```bash
read -rs GITHUB_PAT
claude mcp add --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer $GITHUB_PAT"
unset GITHUB_PAT
```

Si votre version de Claude Code refuse cette forme, la page du serveur GitHub donne la forme `claude mcp add-json github '{...}'` pour les versions récentes. Tapez-la dans PowerShell 7, pas dans Windows PowerShell 5.1 : la version 5.1 retire les guillemets doubles d'un texte JSON passé à un programme, et la commande échoue.

> **À savoir.** Claude Code range ce jeton dans son fichier de configuration, en clair. C'est pourquoi le jeton est limité à un dépôt et à une courte durée. Vous le révoquez à la fin de la formation.

**Vérifier** : voir l'étape 6.

### 5. Brancher GitLab (rôle Dev)

La page officielle de GitLab décrit un serveur MCP intégré (disponible en production depuis GitLab 19.5). La fiche de formation parle encore d'un mode « expérimental » de `glab` : **relisez la commande avec le formateur avant de la lancer**.

```powershell
claude mcp add -s user --transport http GitLab https://gitlab.com/api/v4/mcp
```

Puis lancez `claude` dans le terminal, tapez `/mcp`, choisissez le serveur GitLab et validez la demande dans votre navigateur (connexion OAuth).

Si vous voulez essayer le mode serveur de `glab` lui-même, regardez d'abord s'il existe sur votre version :

```powershell
glab mcp --help
```

Si la commande n'existe pas, ou si elle est marquée expérimentale, notez-le dans votre journal et passez à l'étape suivante.

**Vérifier** : voir l'étape 6.

### 6. Vérifier les connexions

Dans le terminal :

```powershell
claude mcp list
```

Dans `claude` (au terminal ; dans l'onglet **Code**, la commande peut ne pas être disponible) :

```text
/mcp
```

Chaque serveur affiche un état : connecté, besoin d'authentification, ou échec. Prenez une **capture d'écran** de la liste : c'est un livrable.

**Vérifier** : `microsoft-learn` est connecté. `github` et GitLab sont connectés ou en attente de votre accord dans le navigateur. Un serveur en échec : relisez la commande, ne l'inventez pas.

Ensuite, posez trois questions sur Azure (rôle **Ops**) :

1. « Quelle est la différence entre un abonnement et un groupe de ressources ? »
2. « Qu'est-ce qu'un groupe de sécurité réseau ? »
3. « Que veut dire désallouer une machine virtuelle ? »

Pour chaque réponse, notez **la source citée** (adresse de la page). Ouvrez-la et vérifiez que la page dit bien cela.

### 7. Tester les règles automatiques (rôle Sécurité)

L'espace de travail contient `CLAUDE.md`, des permissions (`.claude/settings.json`) et deux règles automatiques (hooks) : l'une bloque les suppressions, l'autre la lecture des secrets.

**Essai A, avec Claude Code.** Dans la conversation, demandez :

```text
Crée un fichier essai.txt, puis supprime-le avec la commande rm.
```

La commande doit être **bloquée**, avec un message qui commence par « Bloqué par la règle de l'équipe Lagune ». Demandez aussi de lire un fichier `.env` : même blocage.

**Essai B, sans Claude Code.** Vous envoyez vous-même une fausse demande à la règle. Dans PowerShell, dans le dossier `lagune-ops`. On appelle le `bash` de Git pour Windows par son chemin complet : la commande `bash` seule est souvent introuvable, ou lance celui de WSL.

```powershell
$bash = "$env:ProgramFiles\Git\bin\bash.exe"
'{"tool_input":{"command":"rm test.txt"}}' | & $bash .claude/hooks/bloquer-suppressions.sh
$LASTEXITCODE
```

Le code de sortie doit être `2` (appel bloqué). Un code `0` veut dire que l'appel passerait.

**Contre-épreuve.** Une commande inoffensive doit passer :

```powershell
'{"tool_input":{"command":"git status"}}' | & $bash .claude/hooks/bloquer-suppressions.sh
$LASTEXITCODE
```

Code attendu : `0`.

macOS ou Linux : `echo '{"tool_input":{"command":"rm test.txt"}}' | bash .claude/hooks/bloquer-suppressions.sh; echo $?` (même chose avec `git status`).

> **Attention à `jq`.** Les règles automatiques lisent leur entrée avec `jq`. Sans `jq`, elles bloquent **tout** avec le message « jq est requis ». Vous croiriez que la règle fonctionne alors qu'elle est cassée : c'est pourquoi la contre-épreuve compte. Si le message parle de `jq`, installez-le (`winget install jqlang.jq`), fermez et rouvrez le terminal, **quittez complètement l'application Claude puis rouvrez-la** (elle ne relit le PATH qu'au démarrage), et recommencez.

**Vérifier** : l'essai A est bloqué, l'essai B donne `2`, la contre-épreuve donne `0`. Relisez ensuite `.claude/settings.json` : trois listes, `allow`, `ask`, `deny`. Dites en une phrase ce que chacune fait.

### 8. La chasse aux hallucinations (toute l'équipe)

Une hallucination est une réponse fausse présentée comme vraie. Exemple attendu : un vieux module PowerShell retiré par Microsoft.

1. Demandez à Claude Code, **sans** lui dire d'utiliser Microsoft Learn : « Donne la commande PowerShell pour lister les utilisateurs de Microsoft 365. »
2. Regardez la réponse. Si elle commence par `Connect-MsolService` (module **MSOnline**), c'est une erreur : ce module est retiré.
3. Redemandez : « Vérifie sur Microsoft Learn et cite la page. » La bonne réponse utilise **Microsoft Graph PowerShell** :

```powershell
Connect-MgGraph -Scopes "User.ReadBasic.All"
Get-MgUser -Top 5
```

4. Vérifiez vous-même sur la page « List users » de Microsoft Graph que l'autorisation citée est bien la plus petite pour lire les utilisateurs. Si la page dit autre chose, **la page a raison**.

Si l'IA ne se trompe pas, essayez une autre question qui change vite : un prix, une date de retrait, une limite. Votre mission est de trouver au moins une erreur, ou de dire honnêtement que vous n'en avez pas trouvé.

Créez le journal sur une branche, depuis PowerShell, dans `lagune-ops` :

```powershell
git switch main
git pull
git switch -c docs/journal-hallucinations
code docs\journal-hallucinations.md
```

Copiez ce plan dans le fichier, remplissez-le, enregistrez (Ctrl+S) :

```markdown
# Journal de la chasse aux hallucinations

| Question posée | Réponse de l'IA (résumé) | Source citée | Vérifié sur Microsoft Learn | Verdict | Correction |
|---|---|---|---|---|---|
| Lister les utilisateurs | Connect-MsolService | aucune | MSOnline retiré en 2025 | Faux | Connect-MgGraph + Get-MgUser |
```

Puis envoyez-le et ouvrez la demande de fusion, à faire relire par un coéquipier (comme au LAB-01) :

```powershell
git add docs/journal-hallucinations.md
git commit -m "Ajoute le journal de la chasse aux hallucinations"
git push -u origin docs/journal-hallucinations
gh pr create --title "Journal de la chasse aux hallucinations" --body "Questions posées, sources vérifiées, erreurs trouvées."
```

**Vérifier** : le journal contient au moins une ligne « Faux » avec sa correction et sa source, ou une ligne qui dit qu'aucune erreur n'a été trouvée sur N questions.

## Pièges

- **Accepter une commande sans la lire.** Si vous ne pouvez pas l'expliquer, vous ne la validez pas.
- **Coller un jeton dans la conversation.** Ne le faites jamais. Un jeton se saisit dans votre terminal, masqué.
- **Croire que la règle fonctionne parce que « tout est bloqué ».** Sans `jq`, tout l'est. Faites la contre-épreuve.
- **Prendre la première réponse pour la bonne.** Demandez la source, ouvrez-la, comparez.
- **Brancher un serveur avec trop de droits.** Un jeton limité à un dépôt et à une courte durée.

## Livrable

- Une capture de la liste des serveurs connectés (`claude mcp list` ou `/mcp`).
- Le journal `docs/journal-hallucinations.md`, avec au moins une erreur trouvée et corrigée, fusionné par demande de fusion.
- Le résultat des essais A et B de l'étape 7.

## Points ouverts

- Le mode serveur MCP de `glab` n'a pas pu être vérifié sur une page officielle pendant la rédaction (la page de commande renvoie vers la page du serveur GitLab). Le formateur relit `glab mcp --help` avant la session.
- La forme de la commande GitHub dépend de la version de Claude Code : la page de GitHub donne deux formes (versions récentes, versions anciennes).
- Les règles automatiques sont des scripts `bash` qui exigent `jq`. Ni `jq` ni `bash` ne figurent dans la liste des outils de la fiche (section 9). Le dépôt modèle prévoit `jq` sur les postes (sous Windows, avec Git Bash). À installer ou à prévoir au jour J-1.
- La commande `/ask` citée sur la page d'Azure Skills est celle de GitHub Copilot CLI. Avec Claude Code, posez la question en langage courant.
- Partage entre la commande `claude` et l'onglet **Code** de l'application (serveurs MCP de `~/.claude.json`, règles automatiques, réglages) : annoncé par la documentation, à vérifier sur un poste de formation avant la session. Si un outil manque dans l'application, les étapes 2 à 8 se font dans le terminal.
- La documentation de l'application ne dit pas si l'onglet **Code** pose la question « faire confiance à ce dossier » pour un dossier local, ni si `/mcp` et `/plugin` y répondent : d'où le passage par `claude` au terminal. Le shell exact du terminal intégré sous Windows n'est pas documenté non plus (d'où la vérification de `$PSVersionTable`).
- Le compte Claude des participants : plan Pro, Max, Team ou Enterprise (le plan gratuit n'a pas Claude Code). À créer et tester au jour J-1.

## Sources

- https://code.claude.com/docs/en/setup (Windows 10 1809+, `irm https://claude.ai/install.ps1 | iex`, Git pour Windows, `claude --version`, `claude doctor`), https://code.claude.com/docs/en/desktop-quickstart (application, onglet Code, Open folder…, plan payant requis), https://code.claude.com/docs/en/authentication (connexion par le navigateur, `/login`), https://code.claude.com/docs/en/desktop (réglages partagés entre l'application et la commande, terminal intégré **Terminal** / Ctrl+`, commandes à panneau indisponibles dans l'onglet Code), https://code.claude.com/docs/en/permissions (« Project allow rules and workspace trust » : les règles `allow` du projet attendent l'accord de confiance, `deny` et `ask` non), https://code.claude.com/docs/en/hooks (sous Windows, hooks lancés par Git Bash, ou PowerShell sans Git Bash)

- https://code.claude.com/docs/en/mcp (`claude mcp add --transport http`, `--header`, `claude mcp list`, `/mcp`)
- https://learn.microsoft.com/api/mcp (point d'accès Microsoft Learn ; page de présentation : https://learn.microsoft.com/training/support/mcp)
- https://learn.microsoft.com/en-us/azure/developer/azure-skills/install (Azure Skills, Node.js LTS, `az login`, `/plugin marketplace add microsoft/azure-skills`, `/plugin install azure@azure-skills`)
- https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-claude.md
- https://docs.gitlab.com/user/model_context_protocol/mcp_server/
- https://code.claude.com/docs/en/hooks (code de sortie 2 = appel bloqué) et https://code.claude.com/docs/en/permissions
- https://techcommunity.microsoft.com/blog/identity/-/4364991 (retrait de MSOnline et AzureAD)
- https://learn.microsoft.com/en-us/graph/api/user-list (page « List users » à relire)
- `17_Videos_Jours/sources.md`, lignes L4, M3, C1, C2

*Conception et animation : Yolea, Abidjan.*
