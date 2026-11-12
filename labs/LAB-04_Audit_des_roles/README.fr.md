# LAB-04 · Audit des rôles : qui a quel rôle, et est-ce justifié ?

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Les commandes de lecture des rôles et la recherche dans le journal d'audit n'ont pas encore été essayées dans un vrai locataire.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J2, 15h15 |
| **Durée** | 45 minutes |
| **Brief vidéo** | J2-L04 (voir aussi J2-V07) |

## Objectif

Dresser le tableau des rôles d'administration de Lagune, **en lecture seule**, et juger chaque ligne : justifié, trop large, ou à retirer. Chaque correction passe par un ticket. Ensuite, retrouver dans le journal d'audit qui a fait quoi.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Ops** | Interroge l'annuaire en lecture seule, avec Claude Code, et produit le tableau. |
| **Sécurité** | Juge chaque ligne : justifié, trop large, à retirer. Cherche dans le journal d'audit. |
| **Dev** | Enregistre le tableau dans le dépôt. Ouvre un ticket pour chaque correction. |

## Prérequis

- LAB-01 à LAB-03 terminés. PowerShell 7 et Microsoft Graph PowerShell installés. Toutes les commandes se tapent dans **PowerShell 7** (`pwsh`), dans votre dossier `lagune-ops` (`Set-Location $HOME\lagune-ops`).
- Un compte qui peut **lire** les rôles : la page Microsoft cite comme rôles minimaux *Directory Readers*, *Global Reader* ou *Privileged Role Administrator*. Le **Lecteur général** (Global Reader) suffit pour lire, et ne peut rien modifier.
- Le LAB-03 a créé les 20 salariés : ils sont la matière de l'audit.
- **Préparé par le formateur** : pour montrer quelque chose à juger, quelques comptes du locataire ont des rôles volontairement discutables (par exemple un stagiaire qui est administrateur général). Il donne aussi à un compte le rôle d'audit pour l'étape 6.
- Règle du lab : **on ne modifie rien**. Aucune commande `New-`, `Set-`, `Update-` ou `Remove-` aujourd'hui.

## Étapes

### 1. Préparer la branche (rôle Dev)

```powershell
git switch main
git pull
git switch -c audit/roles
New-Item -ItemType Directory -Force docs | Out-Null
```

### 2. Se connecter avec une seule autorisation de lecture (rôle Ops)

La page Microsoft « List unifiedRoleAssignments » donne, du moins privilégié au plus privilégié : `RoleManagement.Read.Directory`, puis `RoleManagement.Read.All`, puis `Directory.Read.All`. On prend la première.

```powershell
Connect-MgGraph -Scopes "RoleManagement.Read.Directory"
```

La fenêtre de connexion liste ce que vous autorisez. Lisez-la : il ne doit y avoir **que de la lecture**.

**Vérifier** : `(Get-MgContext).Scopes` affiche `RoleManagement.Read.Directory`.

> **À vérifier par vous.** La page citée couvre la liste des **affectations** de rôles. Pour la liste des **définitions** de rôles (les noms), relisez la page Microsoft « List roleDefinitions » : demandez-la à Claude Code avec le serveur Microsoft Learn, et vérifiez l'autorisation citée. C'est un exercice de plus contre les hallucinations.

### 3. Dresser l'inventaire (rôle Ops)

Les noms des rôles, puis les affectations avec la personne :

```powershell
$roles = Get-MgRoleManagementDirectoryRoleDefinition -All
$affectations = Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty "principal"

$tableau = foreach ($a in $affectations) {
    $nomRole = ($roles | Where-Object Id -eq $a.RoleDefinitionId).DisplayName
    [pscustomobject]@{
        Role    = $nomRole
        Type    = $a.Principal.AdditionalProperties['@odata.type']
        Nom     = $a.Principal.AdditionalProperties['displayName']
        Compte  = $a.Principal.AdditionalProperties['userPrincipalName']
        Portee  = $a.DirectoryScopeId
    }
}
$tableau | Sort-Object Role | Format-Table -AutoSize
```

Si les colonnes `Nom` et `Compte` sont vides, c'est que l'objet reçu n'a pas ces champs : demandez à Claude Code d'adapter la commande, puis **relisez-la** avant de la lancer. Elle doit rester une commande de lecture.

Gardez une copie hors du dépôt pour travailler :

```powershell
$tableau | Sort-Object Role | Export-Csv -Path (Join-Path $env:TEMP "roles-lagune.csv") -NoTypeInformation -Encoding utf8
```

**Vérifier** : le tableau affiche au moins un administrateur général. Chaque ligne a un rôle et un nom.

Fermez la session quand l'inventaire est fait :

```powershell
Disconnect-MgGraph
```

> **Limite.** Cette commande liste les affectations **actives**. Les rôles « éligibles » (PIM, licence P2) ne sont pas ici : notez dans votre rapport que cet audit ne les couvre pas.

### 4. Juger chaque ligne (rôle Sécurité)

Créez `docs/audit-roles.md` (`code docs\audit-roles.md`, puis Ctrl+S pour enregistrer). Pour chaque ligne du tableau, une décision :

```markdown
# Audit des rôles d'administration · Lagune

Audit en lecture seule, réalisé le <DATE> par <ÉQUIPE>.

| Rôle | Compte | Justification donnée | Verdict | Ticket |
|---|---|---|---|---|
| Administrateur général | <compte> | Responsable de la sécurité | Justifié | – |
| Administrateur général | <compte stagiaire> | Aucune | À retirer | #<n> |
| Administrateur des utilisateurs | <compte> | Crée les comptes à l'arrivée | Trop large pour sa tâche : un rôle plus étroit suffit | #<n> |
```

Trois verdicts seulement :

- **Justifié** : le rôle correspond à la tâche.
- **Trop large** : un rôle plus étroit suffirait.
- **À retirer** : aucune raison de garder ce rôle.

Repères pour juger (Microsoft Learn, bonnes pratiques des rôles Entra) :

- moins de **cinq** administrateurs généraux dans l'organisation ;
- un compte d'administration ne sert qu'à administrer ;
- on choisit le rôle le plus étroit qui suffit (*Administrateur des utilisateurs*, *Administrateur de licences*, *Lecteur général*).

Vous pouvez demander à Claude Code de préparer une première proposition de verdicts. **Vous** décidez ligne par ligne, et vous écrivez la justification vous-même. Les comptes d'urgence du formateur sont des administrateurs généraux voulus : notez-les « justifié, compte d'urgence », sans y toucher.

**Vérifier** : chaque ligne a un verdict et, si ce n'est pas « Justifié », un numéro de ticket (étape suivante).

### 5. Un ticket par correction (rôle Dev)

On ne corrige pas pendant l'audit. Un ticket par ligne à corriger :

```powershell
gh issue create --title "Retirer le rôle Administrateur général du compte <compte stagiaire>" --body "Audit des rôles : aucune justification. Verdict : à retirer. Voir docs/audit-roles.md. Correction à faire par un administrateur, hors audit."
```

Reportez le numéro du ticket dans le tableau.

**Vérifier** : `gh issue list` montre un ticket par correction. Aucun rôle n'a changé dans le locataire.

Enregistrez, puis demande de fusion :

```powershell
git add docs/audit-roles.md
git commit -m "Ajoute l'audit des rôles d'administration"
git push -u origin audit/roles
gh pr create --title "Audit des rôles d'administration" --body "Audit en lecture seule. Une correction par ticket."
```

Un coéquipier relit et approuve, comme dans les labs précédents, avec le numéro de la demande (`gh pr list`, `gh pr diff <NUMERO>`, `gh pr review <NUMERO> --approve`).

### 6. Le journal d'audit dans Microsoft Purview (rôle Sécurité)

Question : **qui a créé les comptes du LAB-03, et quand ?**

1. Ouvrez le portail Microsoft Purview : https://purview.microsoft.com
2. Choisissez la solution **Audit** (si la carte n'apparaît pas : **View all solutions**, puis **Audit**).
3. Sur la page **Search**, réglez la plage de dates (UTC) pour couvrir le LAB-03, choisissez l'utilisateur qui a lancé le script, puis **Search**.
4. Dans les résultats, repérez les activités de création de comptes et d'ajout au groupe. Notez : date, compte, activité.

Il faut un des rôles **Audit Logs** ou **View-Only Audit Logs** dans le portail Purview. Sans lui, la page refuse. Le formateur vous l'a donné ; sinon, notez-le comme point bloquant.

À savoir :

- la recherche est lancée comme une tâche : elle peut prendre quelques minutes ;
- les traces d'un événement arrivent en général 60 à 90 minutes après l'événement, parfois plus ;
- sans licence E5, les traces sont gardées 180 jours.

**Vérifier** : vous avez écrit, dans `docs/audit-roles.md`, une section « Journal d'audit » avec au moins une ligne (date, qui, quoi). Si la recherche ne renvoie encore rien, écrivez-le tel quel, avec l'heure de la recherche, et refaites-la plus tard.

## Pièges

- **Corriger pendant l'audit.** Un audit se fait en lecture seule. Chaque correction passe par un ticket.
- **Demander trop d'autorisations.** `Directory.Read.All` et surtout toute autorisation `ReadWrite` sont inutiles ici.
- **Laisser Claude Code lancer une commande qui modifie.** Les commandes `Set-`, `New-`, `Remove-` n'ont rien à faire dans cet audit. Lisez chaque commande avant de valider.
- **Croire que le tableau est complet.** Les rôles éligibles (PIM) n'y sont pas.
- **Chercher dans le journal d'audit trop tôt.** Les traces ont un délai.
- **Commiter un export complet de comptes réels.** Ici, les comptes sont fictifs. Dans la vraie vie, l'export reste hors du dépôt.

## Livrable

- `docs/audit-roles.md` dans le dépôt : le tableau jugé et la section « Journal d'audit ».
- Un ticket pour chaque correction.
- La demande de fusion relue et fusionnée.

## Points ouverts

- Les autorisations de lecture ont été relues sur la page des **affectations** de rôles seulement. Celle des **définitions** reste à relire sur le locataire (voir l'étape 2).
- La forme exacte de l'objet `Principal` renvoyé par `-ExpandProperty` n'a pas été essayée dans un locataire.
- Le nom exact des activités de création de compte dans Purview n'a pas été vérifié ; l'équipe les repère dans les résultats.
- Les menus des portails changent : les captures du formateur font foi.

## Sources

- https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roleassignments (`RoleManagement.Read.Directory`, `Get-MgRoleManagementDirectoryRoleAssignment`, rôles minimaux Directory Readers, Global Reader, Privileged Role Administrator)
- https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roledefinitions (à relire)
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices (bonnes pratiques, moins de cinq administrateurs généraux)
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference (rôles intégrés)
- https://learn.microsoft.com/en-us/purview/audit-search (rôles Audit Logs et View-Only Audit Logs, durée de conservation, délai)
- https://cli.github.com/manual/gh_issue_create
- `17_Videos_Jours/sources.md` ; script J2-V07

*Conception et animation : Yolea, Abidjan.*
