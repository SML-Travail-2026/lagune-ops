# LAB-07 · La boutique par Terraform et le pipeline

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Rien de ce guide n'a encore été exécuté dans un vrai locataire : ni la connexion OpenID Connect, ni le déploiement réel, ni l'émission du certificat géré, ni le scan ZAP du site en ligne.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J4, 08h30 à 12h30 (pause de 15 minutes au milieu) |
| **Durée** | la matinée (4 heures) |
| **Brief vidéo** | J4-L07 (voir aussi J4-V01 à J4-V04) |

## Objectif

Mettre la boutique de Lagune (OWASP Juice Shop) en ligne par Terraform et par le pipeline GitHub Actions. En HTTPS, sur un sous-domaine, et accessible depuis la salle seulement. Lire chaque plan avant d'approuver.

Dans ce lab, le code est déjà dans votre dépôt, dans le dossier `kit/lab-07/`. Il a été écrit par le formateur : vous le déplacez à sa place, puis vous l'expliquez avec Claude Code. On n'invente rien : mêmes fichiers, mêmes noms, mêmes variables.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Dev** | Place le code du lab, le comprend avec Claude Code, ouvre la demande de fusion. |
| **Ops** | Relit chaque plan. Ajoute les deux lignes chez l'hébergeur du domaine. Approuve le déploiement. |
| **Sécurité** | Vérifie les restrictions d'accès. Lit les rapports de Trivy et d'OWASP ZAP. Fait vérifier la boutique par Claude Code dans un navigateur. |

## Prérequis

- LAB-01 à LAB-06 terminés. Toutes les commandes se tapent dans **PowerShell 7**, dans votre dossier `lagune-ops` (`Set-Location $HOME\lagune-ops`).
- Terraform installé : `terraform -version` affiche un numéro. Sinon : `winget install Hashicorp.Terraform`, puis fermez et rouvrez le terminal.
- **Préparé par le formateur** (une seule fois). Vous ne le faites pas, vous le **vérifiez** :
  - un compte de stockage pour l'état Terraform (conteneur `tfstate`) ;
  - **deux** identités Azure du pipeline **sans mot de passe** (OpenID Connect) : *lagune-plan*, en **lecture seule**, pour l'environnement `plan` (le plan d'une demande de fusion ne peut donc rien déployer), et *lagune-deploy* (rôle Contributeur limité à l'abonnement de formation) pour `production` et `destruction` ;
  - **les identifiants fédérés (OpenID Connect) de votre dépôt `<ORGANISATION>/lagune-ops`**, ajoutés par le formateur dans le locataire de formation, et **votre préfixe et vos identifiants** (client, locataire, abonnement), qu'il vous a remis ;
  - un dépôt GitHub **public** (sans donnée réelle ni secret dedans), dans l'organisation de votre équipe : sur GitHub Free, Pro et Team, les relecteurs obligatoires d'un environnement n'existent que pour les dépôts publics. Voir « Points ouverts » ;
  - dans votre dépôt GitHub : les environnements `plan`, `production` (avec relecteurs obligatoires) et `destruction` ; dans **chaque** environnement, les secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (avec l'identité propre à l'environnement), que **l'équipe enregistre elle-même** avec les identifiants du formateur ; le secret de dépôt `ANTHROPIC_API_KEY` (clé plafonnée remise par le formateur, une seule pour l'équipe) ; les variables `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `ROOM_IP_CIDR`, `LAGUNE_PREFIX`, `CUSTOM_HOSTNAME`, `ENABLE_CUSTOM_DOMAIN` (à `false`), `BUDGET_CONTACT_EMAIL`, `DESTRUCTION_AUTO` ;
  - le préfixe de votre équipe (`LAGUNE_PREFIX`, par exemple `lagune01`) : le nom de l'application Azure est unique dans le monde ;
  - le nom de domaine de **votre équipe** `<DOMAINE_EQUIPE>`, acheté avant le cours (voir le courriel d'avant-cours), et l'accès à sa zone DNS ; la boutique répondra sur `boutique.<DOMAINE_EQUIPE>` ;
  - l'adresse IP publique de la salle dans `ROOM_IP_CIDR` (au format `a.b.c.d/32`).
- Node.js 18 ou plus pour Playwright (`node --version`).

Pour vérifier ce que le formateur a préparé, sans rien voir de secret (la liste ne montre que les noms des secrets) :

```powershell
gh secret list --env plan
gh secret list --env production
gh secret list --env destruction
gh variable list
```

**Vérifier** : les trois secrets Azure dans chacun des trois environnements et les huit variables de la liste ci-dessus sont présents. Il manque quelque chose ? Prévenez le formateur, ne le créez pas vous-même.

## Étapes

### 1. Mettre le code du lab en place (rôle Dev)

On travaille sur une branche. On déplace le dossier `terraform/`, les deux pipelines GitHub depuis `kit/lab-07/`. Le fichier `.gitignore` de la racine est déjà complet : on n'y touche pas.

```powershell
git switch main
git pull
git switch -c infra/boutique-terraform
git mv kit\lab-07\terraform terraform
New-Item -ItemType Directory -Force .github\workflows | Out-Null
git mv kit\lab-07\.github\workflows\deploy.yml .github\workflows\deploy.yml
git mv kit\lab-07\.github\workflows\destroy.yml .github\workflows\destroy.yml
```

**Vérifier** : `Get-ChildItem .\terraform` montre `main.tf`, `variables.tf`, `versions.tf`, `outputs.tf`, `terraform.tfvars.example`, `backend.hcl.example` et `.terraform.lock.hcl`. Il n'y a **pas** de dossier `.terraform`, ni de fichier `*.tfvars` ou `*.tfstate`.

`kit/lab-07/.gitlab-ci.yml` reste dans le kit : c'est le même pipeline côté GitLab, montré par le formateur. Le déplacer lancerait le pipeline sur votre miroir GitLab à chaque envoi.

### 2. Comprendre le code avant de l'envoyer (rôles Dev et Sécurité)

Ouvrez `terraform/main.tf` avec Claude Code :

```text
Explique terraform/main.tf, bloc par bloc, en français simple.
Pourquoi le plan App Service est-il en B1 ? Que fait ip_restriction_default_action = "Deny" ?
À quoi sert l'étiquette expiration ? Cite la documentation du fournisseur azurerm.
```

Vous devez pouvoir répondre :

- Quelles ressources le code crée (avec `enable_custom_domain = false`) : un groupe de ressources, un plan App Service, une application web Linux, un budget. **Quatre.**
- Pourquoi l'image est épinglée (`v20.3.0`, jamais « latest »).
- Pourquoi l'accès est refusé à tout, sauf à `ROOM_IP_CIDR`, y compris sur le site d'administration (SCM).
- Pourquoi `https_only`, TLS 1.2 minimum et FTPS désactivé.

**Vérifier** : chaque personne de l'équipe a expliqué un bloc à voix haute. Les réponses de Claude sont comparées avec la page du fournisseur azurerm.

### 3. Vérifier en local, sans toucher à Azure (rôle Dev)

```powershell
Set-Location terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
Set-Location ..
```

Pas de `terraform plan` ni de `terraform apply` en local : le plan et l'application se font **uniquement** dans le pipeline.

**Vérifier** : `terraform fmt -check` ne dit rien (code déjà bien formaté), et `terraform validate` répond `Success! The configuration is valid.`

### 4. Demande de fusion : le pipeline planifie (rôles Dev et Ops)

```powershell
git add terraform .github
git commit -m "Ajoute la boutique Juice Shop en Terraform et le pipeline"
git push -u origin infra/boutique-terraform
gh pr create --title "La boutique de Lagune en Terraform" --body "Code du lab : groupe de ressources, plan B1, application Juice Shop, budget. Accès limité à l'IP de la salle."
```

Suivez le pipeline :

```powershell
gh run list
gh run watch
```

Sur une **demande de fusion**, le pipeline fait : **Vérifier le code** (format, validation, Trivy), puis **Planifier**. Il n'applique rien, et le plan d'une demande de fusion est calculé avec l'identité en **lecture seule**.

Le rôle **Ops** lit le plan dans le journal :

```powershell
gh run view <NUMERO_DU_RUN> --log
```

Cherchez la ligne `Plan:`. Avec le code du lab, vous devez lire **4 à ajouter, 0 à modifier, 0 à détruire**.

Écrivez le résultat dans un commentaire de la demande. Sur votre poste, vous êtes sur `main` : donnez le numéro de la demande (`gh pr list`) :

```powershell
gh pr comment <NUMERO_PR> --body "Plan lu : 4 à créer (groupe de ressources, plan B1, application web, budget), 0 à modifier, 0 à détruire. Conforme à ce qu'on attend."
```

Pas de plan lu, pas d'approbation.

**Vérifier** : les tâches « Vérifier le code » et « Planifier » sont vertes. Le plan correspond à ce que vous avez prédit à l'étape 2. Un plan qui annonce une **destruction** que personne n'attend : arrêtez et cherchez pourquoi.

Un coéquipier relit et approuve :

```powershell
gh pr diff <NUMERO_PR>
gh pr review <NUMERO_PR> --approve --body "Code relu, plan lu."
```

### 5. Fusion, approbation et déploiement (rôles Ops et Sécurité)

```powershell
gh pr merge --merge --delete-branch
git switch main
git pull
gh run list
```

La fusion sur `main` lance le pipeline complet : **Vérifier**, **Planifier**, puis **Appliquer puis tester (après approbation)**. Cette dernière tâche **attend** un relecteur de l'environnement `production`.

Le relecteur désigné (rôle **Ops**) :

1. Ouvre la page de l'exécution sur GitHub (**Actions**, puis l'exécution « Déployer la boutique »).
2. Lit le plan de la tâche « Planifier » une dernière fois.
3. Clique **Review deployments**, coche `production`, écrit un commentaire, puis **Approve and deploy**.

L'application applique **exactement le plan approuvé**, pas un nouveau plan.

**Vérifier** : la tâche « Appliquer puis tester » est verte. Puis, dans le portail Azure ou en ligne de commande :

```powershell
az webapp show --resource-group rg-<PREFIXE>-boutique --name app-<PREFIXE>-boutique --query "{etat:state, hote:defaultHostName}" --output table
```

L'état est `Running`. Notez le nom d'hôte par défaut (`app-<PREFIXE>-boutique.azurewebsites.net`).

Le scan OWASP ZAP (passif) tourne dans la **même tâche**, juste après l'application : il n'y a **qu'une seule approbation** pour tout le déploiement.

### 6. Vérifier l'accès depuis la salle et depuis ailleurs (rôle Sécurité)

Depuis le poste de la salle :

```powershell
curl.exe -I https://app-<PREFIXE>-boutique.azurewebsites.net
```

Attendu : `HTTP/1.1 200` ou `HTTP/2 200`. Le premier chargement peut être lent (démarrage du conteneur).

Depuis un téléphone sur le réseau mobile (pas le Wi-Fi de la salle), ouvrez la même adresse. Attendu : accès **refusé** (erreur 403).

**Vérifier** : la salle voit la boutique, l'extérieur non. C'est exactement la règle voulue : une application volontairement vulnérable ne doit jamais être ouverte à tout Internet.

### 7. Le sous-domaine et le certificat, en deux temps (rôle Ops)

**Temps 1 : les deux lignes chez l'hébergeur du domaine** (dans le compte de votre équipe chez son fournisseur DNS). Dans la zone DNS de `<DOMAINE_EQUIPE>`, créez :

| Type | Nom | Valeur |
|---|---|---|
| CNAME | `boutique` | `app-<PREFIXE>-boutique.azurewebsites.net` |
| TXT | `asuid.boutique` | la valeur du « Custom Domain Verification ID » de l'application |

Le CNAME pointe **directement** vers `azurewebsites.net`, sans relais. Si votre zone est chez Cloudflare, mettez les deux lignes en « DNS seulement » (nuage gris) : derrière le proxy, le certificat géré ne s'émet pas et la règle « salle seulement » verrait l'adresse de Cloudflare au lieu de celle de la salle.

Où lire cette valeur : portail Azure, votre application `app-<PREFIXE>-boutique`, **Custom domains**, champ **Custom Domain Verification ID**. Ce n'est pas un secret : c'est une preuve de propriété du domaine. Le formateur peut aussi la lire avec `terraform output -raw custom_domain_verification_id`, s'il a accès à l'état.

Attendez la propagation, puis vérifiez :

```powershell
Resolve-DnsName -Name boutique.<DOMAINE_EQUIPE> -Type CNAME
Resolve-DnsName -Name asuid.boutique.<DOMAINE_EQUIPE> -Type TXT
```

**Vérifier** : les deux réponses affichent les valeurs attendues. **N'allez pas à l'étape suivante avant.**

**Temps 2 : activer le sous-domaine par le pipeline.**

```powershell
gh variable set CUSTOM_HOSTNAME --body "boutique.<DOMAINE_EQUIPE>"
gh variable set ENABLE_CUSTOM_DOMAIN --body "true"
gh workflow run deploy.yml --ref main
gh run list
```

Le pipeline replanifie. Le rôle **Ops** lit le nouveau plan : il doit annoncer **3 à ajouter** (la liaison du nom, le certificat géré, la liaison du certificat) et **0 à détruire**. Il approuve `production` comme avant.

Le certificat géré est gratuit, renouvelé automatiquement, et demande un plan App Service Basic ou plus (B1 convient). Son émission peut prendre quelques minutes.

**Vérifier**, depuis la salle :

```powershell
curl.exe -I https://boutique.<DOMAINE_EQUIPE>
```

Attendu : réponse `200`, sans erreur de certificat. Dans le navigateur, le cadenas HTTPS apparaît.

### 8. Faire vérifier la boutique par Claude Code (rôle Sécurité)

Ajoutez le serveur MCP Playwright (Node.js 18 ou plus), dans PowerShell, dans `lagune-ops`. Les guillemets simples autour du nom du paquet sont nécessaires : sans eux, PowerShell lit `@playwright` comme une variable (« splatting ») et la commande est cassée.

```powershell
claude mcp add playwright -- npx '@playwright/mcp@latest'
```

macOS ou Linux : `claude mcp add playwright -- npx @playwright/mcp@latest`.

Puis, dans Claude Code (lancez `claude` dans le terminal, ou ouvrez une nouvelle session dans l'onglet **Code** pour qu'il voie le nouveau serveur) :

```text
Ouvre https://boutique.<DOMAINE_EQUIPE>, vérifie que la page répond, que le titre est bon et
que la connexion est chiffrée sans erreur de certificat. Rapporte une capture d'écran.
```

Autorisez chaque outil du navigateur quand Claude Code le demande. Le navigateur tourne sur **votre poste**, dans la salle : il passe la restriction d'accès. Lancé de chez vous, le même test serait refusé, et c'est voulu.

Copiez la capture dans `docs/captures/boutique.png` (Claude Code vous indique où il l'a enregistrée) :

```powershell
New-Item -ItemType Directory -Force docs\captures | Out-Null
Copy-Item -Path "<CHEMIN_DE_LA_CAPTURE>" -Destination docs\captures\boutique.png
```

**Vérifier** : Claude Code a rapporté que la page répond et que la connexion est chiffrée. La capture montre la boutique.

### 9. Lire les rapports de sécurité (rôle Sécurité)

**Trivy** (analyse du code d'infrastructure, avant le déploiement). Dans le journal de la tâche « Vérifier le code » :

```powershell
gh run view <NUMERO_DU_RUN> --log
```

Le pipeline est réglé pour échouer sur les niveaux `HIGH` et `CRITICAL` seulement. Un code propre n'affiche donc rien de grave.

**OWASP ZAP** (scan de base, passif, du site en ligne). Téléchargez le rapport :

```powershell
gh run download <NUMERO_DU_RUN> --name rapport-zap --dir rapport-zap
```

Ouvrez le fichier `.html` du dossier `rapport-zap` dans un navigateur. Choisissez **trois alertes**. Pour chacune : son niveau de risque, ce qu'elle veut dire, et une idée de correction. Demandez à Claude Code d'expliquer la faille et la bonne pratique.

Écrivez le résumé dans `docs/rapport-zap-resume.md`. Pour chaque alerte à traiter, ouvrez un ticket :

```powershell
gh issue create --title "ZAP : <titre de l'alerte>" --body "Niveau : <niveau>. Correction proposée : <idée>."
```

Le dossier `rapport-zap` et le résumé ne contiennent que des données de la boutique de démonstration.

Pour le scan, le pipeline ouvre une **exception d'accès temporaire** pour l'exécuteur GitHub, puis la retire à la fin quoi qu'il arrive. Vérifiez qu'elle a bien disparu :

```powershell
az webapp config access-restriction show --resource-group rg-<PREFIXE>-boutique --name app-<PREFIXE>-boutique
```

**Vérifier** : la sortie ne contient **aucune** règle `zap-runner`. Il reste la règle `salle-de-formation`.

### 10. Enregistrer (rôle Dev)

```powershell
git switch main
git pull
git switch -c docs/rapports-boutique
git add docs
git commit -m "Ajoute la capture de la boutique et le résumé du rapport ZAP"
git push -u origin docs/rapports-boutique
gh pr create --title "Capture et résumé ZAP de la boutique" --body "Capture Playwright, trois alertes ZAP et leurs tickets."
```

Un coéquipier relit et approuve, comme toujours.

## Démonstrations du formateur (hors de ce lab)

- **GitLab CI/CD** : le fichier `.gitlab-ci.yml` est le même pipeline côté GitLab. Le formateur le montre ; vous ne l'exécutez pas.
- **Ansible** : la démonstration Ansible du formateur (hors de votre dépôt) configure la VM **Windows Server du J3** (IIS, dossier `C:\Lagune`, page d'accueil) par SSH. La VM n'a pas d'adresse publique : le formateur lance la démonstration depuis une machine du même réseau virtuel, la VM étant démarrée. Ce lab **n'en dépend pas** : ne l'attendez pas et ne l'exécutez pas.

## Pièges

- **Appliquer un plan sans l'avoir lu.** Pas de plan lu, pas d'approbation.
- **Activer `ENABLE_CUSTOM_DOMAIN` avant que le CNAME et le TXT `asuid` existent.** Le déploiement échoue sur la liaison du nom. Remettez la variable à `false`, créez les lignes DNS, attendez, recommencez.
- **Copier le dossier `.terraform` ou un fichier `*.tfvars`.** Ni l'un ni l'autre n'a sa place dans le dépôt.
- **Oublier de lire une ligne « à détruire ».** Un plan qui détruit sans que personne l'ait voulu est un signal d'arrêt.
- **Deux équipes avec le même préfixe.** Le nom de l'application existe déjà ailleurs.
- **Ouvrir la boutique à tout Internet « pour tester ».** Jamais. Si vous êtes bloqué, vérifiez `ROOM_IP_CIDR`.
- **L'adresse IP de la salle a changé.** Le formateur met à jour `ROOM_IP_CIDR`, puis le pipeline replanifie.

## Livrable

- Une exécution complète du pipeline : vérifier, planifier, **approuver**, appliquer, tester (ZAP). L'approbation est visible dans l'historique de l'exécution.
- La capture de la boutique en ligne (`docs/captures/boutique.png`).
- Le résumé du rapport ZAP (`docs/rapport-zap-resume.md`) et ses tickets.
- Les demandes de fusion relues.

## Points ouverts

- **Dépôt public, dans l'organisation de l'équipe (décision du 7 novembre 2026).** Sur GitHub Free, Pro et Team, les relecteurs obligatoires d'un environnement n'existent que pour les **dépôts publics** : sur un dépôt privé, l'approbation du déploiement disparaîtrait. Le cours utilise donc un dépôt **public** (sans donnée réelle ni secret). Variante privée : le miroir GitLab avec le bouton de déploiement manuel (voir plus bas). Les approbations de déploiement GitLab demandent l'offre Premium ou Ultimate.
- **Ansible** : la démonstration cible la VM Windows du J3 en SSH et demande Ansible 2.18 ou plus, la collection `ansible.windows` (dans la démonstration du formateur) et OpenSSH actif sur la VM. La préparation de la VM pour SSH n'est pas décrite dans le LAB-06 : à prévoir par le formateur. Ce lab n'en dépend pas.
- **Identité du plan** : la solution lit le plan avec une identité en lecture seule. Ses droits (lecture, accès à l'état, lecture de la configuration de l'application) n'ont pas été essayés sur un vrai abonnement.
- **Certificat et restrictions d'IP** : la page Microsoft de novembre 2025 dit que l'émission fonctionne malgré les restrictions d'IP pour un sous-domaine. Une page générale dit encore le contraire pour un domaine racine. À confirmer en conditions réelles.
- **Valeur `asuid`** : elle se lit dans le portail. La commande `az webapp show` renvoie aussi un champ de ce genre, mais son nom exact n'a pas été vérifié ici.
- **Rapport ZAP** : le nom exact des fichiers dans l'artefact `rapport-zap` n'a pas été vérifié.
- **`az webapp config access-restriction show`** : la commande n'a pas été relue sur sa page de référence pendant la rédaction (seules `add` et `remove` l'ont été).

## Sources

- https://developer.hashicorp.com/terraform/cli/commands (init, fmt, validate, plan, apply)
- https://developer.hashicorp.com/terraform/language/backend/azurerm
- https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app
- https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_managed_certificate
- https://learn.microsoft.com/en-us/azure/app-service/configure-ssl-certificate
- https://learn.microsoft.com/en-us/azure/app-service/app-service-managed-certificate-changes-july-2025
- https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain
- https://learn.microsoft.com/en-us/cli/azure/webapp/config/access-restriction
- https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust
- https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments
- https://github.com/microsoft/playwright-mcp
- https://www.zaproxy.org/docs/docker/baseline-scan/ et https://github.com/zaproxy/action-baseline
- https://github.com/aquasecurity/trivy-action
- https://docs.gitlab.com/ci/cloud_services/azure/ (démonstration)
- `17_Videos_Jours/sources.md`, lignes T1 à T14, G1 à G10, L1 à L5, C3 ; dépôt modèle, dossier `kit/lab-07/` (`terraform/`, `.github/workflows/deploy.yml`, `destroy.yml`)

*Conception et animation : Yolea, Abidjan.*
