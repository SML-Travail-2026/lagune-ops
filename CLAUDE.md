# CLAUDE.md · dépôt lagune-ops

Consignes pour Claude Code dans ce dépôt. Elles s'ajoutent aux règles automatiques de
`.claude/settings.json` (permissions et hooks) : un garde-fou, pas un bac à sable. Un humain
relit toujours ce qui est lancé.

## Contexte
- Entreprise **fictive** : Lagune Services, Abidjan. Domaine `lagune.example`.
- Équipe : trois administrateurs débutants en formation. Explique simplement, en français,
  et donne le terme anglais de l'interface entre parenthèses la première fois.
- Contenu du dépôt (dépôt de départ ; chaque kit est déplacé à sa place par une demande de fusion, pendant son lab) :
  - `kit/lab-03/` : `scripts/Import-LaguneUsers.ps1` + `data/salaries-lagune.csv` (arrivée des 20 salariés) et `.github/workflows/claude-review.yml` (relecture des demandes de fusion).
  - `kit/lab-07/` : `terraform/` (la boutique OWASP Juice Shop sur Azure App Service, Linux), `.github/workflows/` (déploiement, destruction) et `.gitlab-ci.yml` (le même pipeline côté GitLab, miroir).
  - Après les labs 3 et 7, ces fichiers sont à la racine : `terraform/`, `scripts/`, `data/`, `.github/workflows/`. Le fichier `.gitlab-ci.yml` reste dans `kit/lab-07/` (lecture seule, démonstration du formateur).
  - `docs/` : la carte des environnements, les journaux et les rapports de l'équipe.
  - `labs/` : les guides des huit labs (français et anglais), à lire, pas à modifier.

## Règles
1. **Jamais de vraies données** : adresses `@lagune.example`, IP de documentation
   `203.0.113.0/24`, identifiants remplacés par `<ID_ABONNEMENT>`, `<ID_LOCATAIRE>`, etc.
2. **Jamais de secret** : ne lis pas `.env`, `*.tfvars`, `*.tfstate`, les clés, ni le fichier
   des mots de passe temporaires ; n'affiche pas de jeton. Les accès Azure passent par
   OpenID Connect (identité fédérée), sans mot de passe stocké.
3. **Jamais de suppression** : `rm`, `terraform destroy`, `az ... delete`, `Remove-Mg*` sont
   bloqués. Une destruction passe par le pipeline « Détruire la boutique », lancé par un humain.
4. **Plan avant action** : `terraform plan` d'abord, explication du plan ligne à ligne, puis
   un humain approuve. `terraform apply` ne se lance que dans le pipeline, après approbation.
5. **Vérifier avant d'affirmer** : toute commande Microsoft vient de la documentation
   officielle (Microsoft Learn), pas de la mémoire. Les modules **MSOnline** et **AzureAD**
   sont retirés : utilise **Microsoft Graph PowerShell** (`Connect-MgGraph`).
6. **Moindre privilège** : demande les permissions Graph minimales
   (`User.Create`, `User.ReadBasic.All`, `GroupMember.ReadWrite.All` pour l'import).
7. **Essai d'abord** : script d'import en essai à blanc, puis `-Apply -First 2`, puis tout.
8. **Cadre légal** : les tests d'intrusion visent uniquement la boutique de la salle, avec
   l'accord écrit du formateur (loi ivoirienne n° 2013-451 sur la cybercriminalité).

## Commandes utiles
- Vérifier : `cd terraform && terraform fmt -check && terraform init -backend=false && terraform validate`
- Essai d'import : `pwsh ./scripts/Import-LaguneUsers.ps1 -CsvPath ./data/salaries-lagune.csv`
- Pipelines : `gh run list`, `gh run view <numéro>`
