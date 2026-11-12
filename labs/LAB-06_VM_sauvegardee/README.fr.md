# LAB-06 · La première machine de Lagune, sauvegardée

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Aucun de ces écrans n'a encore été parcouru dans l'abonnement de formation. Les noms de menus du portail Azure changent souvent.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J3, 15h15 (séance Azure) |
| **Durée** | le reste de la séance, après les vidéos (environ 75 minutes) |
| **Brief vidéo** | J3-L06 (voir aussi J3-V06 à J3-V09) |

## Objectif

Créer la première machine virtuelle de Lagune, **sans adresse IP publique**. S'y connecter par Azure Bastion. Régler l'arrêt automatique. Activer sa sauvegarde. Écrire la fiche de coût.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Ops** | Crée le groupe de ressources, ses étiquettes, l'alerte de budget, le réseau et la machine. |
| **Sécurité** | Vérifie le groupe de sécurité réseau. Range le mot de passe dans le coffre de l'équipe. |
| **Dev** | Demande à Claude Code le coût mensuel et la façon d'éteindre la machine, et vérifie la réponse sur la calculatrice officielle. |

## Prérequis

- LAB-01 à LAB-05 terminés. Vous avez le rôle Propriétaire ou Contributeur sur votre groupe de ressources, ou sur l'abonnement de formation.
- **Préparé par le formateur** :
  - la région de formation : `<REGION_FORMATION>` ;
  - la taille de machine autorisée par la stratégie Azure : `<TAILLE_AUTORISEE>` ;
  - une alerte de budget sur l'abonnement, et des règles qui limitent régions et tailles ;
  - le coffre de mots de passe de l'équipe.
- **Vérifiez que votre région accepte Bastion Developer.** Bastion Developer est gratuit, mais il ne gère qu'**une machine à la fois** et n'existe que dans **certaines régions**. Regardez la liste « Regional availability » de la page https://learn.microsoft.com/en-us/azure/bastion/bastion-sku-comparison. Si la région n'y figure pas, passez à la **variante Bastion Basic** de l'étape 5 (payante, à supprimer le soir même).
- Un nom de préfixe court et unique pour votre équipe : `<PREFIXE>` (par exemple `lagune01`).

## Étapes

### 1. Le groupe de ressources et ses étiquettes (rôle Ops)

Le coût d'abord : un groupe de ressources, la « boîte » du projet, avec des étiquettes (tags).

Dans le portail Azure (https://portal.azure.com) : **Resource groups**, **Create**.

- Nom : `rg-<PREFIXE>-vm`
- Région : `<REGION_FORMATION>`
- Onglet **Tags** : ajoutez ces cinq étiquettes (ce sont les mêmes clés que celles du code Terraform du LAB-07) :

| Nom | Valeur |
|---|---|
| projet | lagune-ops |
| formation | AZM-201 |
| environnement | formation |
| proprietaire | `<NOM_DE_L_EQUIPE>` |
| expiration | `<AAAA-MM-JJ>` (le dernier jour de la formation) |

Autre voie, par la ligne de commande :

```powershell
az group create --name rg-<PREFIXE>-vm --location <REGION_FORMATION> --tags projet=lagune-ops formation=AZM-201 environnement=formation proprietaire=<NOM_DE_L_EQUIPE> expiration=<AAAA-MM-JJ>
```

**Vérifier** :

```powershell
az group show --name rg-<PREFIXE>-vm --query "{nom:name, region:location, etiquettes:tags}" --output json
```

Les cinq étiquettes apparaissent.

### 2. L'alerte de budget (rôle Ops)

Portail Azure : **Cost Management + Billing** (ou **Cost Management**), **Budgets**, **Add**.

- Portée : votre groupe de ressources `rg-<PREFIXE>-vm`.
- Montant mensuel : celui que le formateur indique (`<MONTANT_BUDGET>`).
- Alertes : une à 50 %, une à 90 %, vers l'adresse de l'équipe.

**Vérifier** : le budget apparaît dans la liste, avec ses deux alertes.

Rappel : un budget **prévient**, il n'arrête rien. Les alertes arrivent avec un peu de retard. C'est à vous d'éteindre.

### 3. Le réseau virtuel, le sous-réseau et le groupe de sécurité réseau (rôles Ops et Sécurité)

Dans `rg-<PREFIXE>-vm`, créez :

| Ressource | Nom | Réglage |
|---|---|---|
| Groupe de sécurité réseau (Network security group) | `nsg-<PREFIXE>-serveurs` | Aucune règle entrante ajoutée |
| Réseau virtuel (Virtual network) | `vnet-<PREFIXE>` | Espace d'adresses `10.10.0.0/16` |
| Sous-réseau (Subnet) dans le réseau virtuel | `snet-serveurs` | `10.10.1.0/24`, groupe de sécurité réseau : `nsg-<PREFIXE>-serveurs` |

Mêmes étiquettes sur chaque ressource (champ **Tags**).

**Vérifier** : ouvrez `nsg-<PREFIXE>-serveurs`, **Inbound security rules**. Il n'y a que les règles par défaut. Demandez à Claude Code :

```text
Explique chaque règle du groupe de sécurité réseau nsg-<PREFIXE>-serveurs, ligne par ligne.
Quelle règle empêche Internet d'entrer ? Cite la page Microsoft Learn.
```

Vous devez pouvoir dire pourquoi **rien** ne vient d'Internet. Une règle que personne ne sait expliquer est à examiner.

### 4. La machine virtuelle Windows Server (rôle Ops)

Portail Azure : **Virtual machines**, **Create**, **Azure virtual machine**.

- Groupe de ressources : `rg-<PREFIXE>-vm`. Nom : `vm-lagune-01`. Région : `<REGION_FORMATION>`.
- Image : **Windows Server** (la version proposée par le portail, édition Datacenter).
- Taille : `<TAILLE_AUTORISEE>`, la plus petite qui suffit. Si le portail refuse une taille, c'est la stratégie du formateur qui fonctionne : prenez une taille autorisée.
- Compte administrateur local : un nom propre à l'équipe (le portail refuse `admin` et `administrator`). Mot de passe **long**, généré par le gestionnaire de mots de passe.
- **Public inbound ports : None.**
- Onglet **Networking** : réseau `vnet-<PREFIXE>`, sous-réseau `snet-serveurs`, **Public IP : None**. Groupe de sécurité réseau de la carte : **None** (celui du sous-réseau suffit).
- Mêmes étiquettes (onglet **Tags**).

Le rôle **Sécurité** range le mot de passe dans le coffre de l'équipe. Il ne va ni dans le dépôt, ni dans un message, ni dans une conversation avec Claude.

**Vérifier** :

```powershell
az vm list-ip-addresses --resource-group rg-<PREFIXE>-vm --name vm-lagune-01 --output table
```

Il y a une adresse privée (`10.10.1.x`) et **aucune adresse publique**.

### 5. Se connecter par Azure Bastion (rôle Ops)

**Variante Bastion Developer (gratuite, une machine à la fois, régions limitées).**

1. Portail Azure, votre machine `vm-lagune-01` (ou son réseau virtuel), **Connect**, **Bastion**.
2. Choisissez le type d'authentification (nom et mot de passe), saisissez l'identifiant et le mot de passe du coffre, puis **Connect**.
3. Bastion Developer se déploie tout seul dans le réseau. La session s'ouvre dans un onglet du navigateur.

**Variante Bastion Basic (payante, si la région n'est pas dans la liste).** La facturation commence dès le déploiement : supprimez-la en fin de séance.

1. Réseau virtuel `vnet-<PREFIXE>`, **Connect**, **Bastion**, **Configure manually**.
2. Niveau : **Basic**. Sous-réseau `AzureBastionSubnet` de taille **/26 ou plus** (par exemple `10.10.2.0/26`). Une adresse IP publique **pour Bastion** (jamais pour la machine).
3. **Review + create**. Comptez une dizaine de minutes.
4. Puis **Connect**, **Bastion** sur la machine.

**Vérifier** : un bureau Windows Server s'affiche dans votre navigateur. Si la fenêtre ne s'ouvre pas, autorisez les fenêtres contextuelles pour le portail.

Si la connexion échoue, regardez les règles du groupe de sécurité réseau avec Claude Code, **jamais** en ouvrant le port 3389 à Internet.

### 6. Un fichier à protéger (rôle Ops)

Dans la machine (à travers Bastion), ouvrez PowerShell et créez un fichier :

```powershell
New-Item -Path C:\Lagune -ItemType Directory -Force
Set-Content -Path C:\Lagune\liste-fournisseurs.txt -Value "Liste fictive des fournisseurs de Lagune Services"
```

Ce fichier servira au J4 : on l'effacera, puis on le restaurera depuis la sauvegarde. Il doit exister **avant** la première copie.

**Vérifier** : `Get-Content C:\Lagune\liste-fournisseurs.txt` affiche la phrase.

### 7. L'arrêt automatique (rôle Ops)

Portail Azure, `vm-lagune-01`, **Operations**, **Auto-shutdown**.

- Interrupteur sur **On**.
- Heure : `19:00`. Fuseau horaire : par défaut UTC (c'est l'heure d'Abidjan).
- Notification avant l'arrêt : **Yes**, avec l'adresse de l'équipe.
- **Save**.

**Vérifier** : en revenant sur la page, l'interrupteur est sur **On** avec l'heure choisie.

Une machine arrêtée depuis le portail est « désallouée » : on ne paie plus son calcul, mais son disque reste facturé, tout comme sa sauvegarde dans le coffre. La sauvegarde de la nuit fonctionne aussi sur une machine éteinte.

### 8. La sauvegarde (rôles Ops et Sécurité)

Portail Azure, `vm-lagune-01`, **Backup**.

1. **Recovery Services vault** : **Create new**. Nom : `rsv-<PREFIXE>`. Le portail le crée dans le même groupe de ressources et la même région que la machine.
2. **Policy sub type** : **Standard**. Politique par défaut : une sauvegarde par jour, gardée 30 jours. Vous pouvez choisir l'heure de la copie (la nuit).
3. **Enable Backup**.
4. Suivez la notification. Quand elle est terminée, rouvrez **Backup** sur la machine.
5. Pour ne pas attendre la nuit : **Backup now**, choisissez la durée de conservation, **OK**. Suivez **View all jobs**.

**Vérifier** :

- la page **Backup** de la machine montre la politique associée ;
- la mention « Warning (Initial backup pending) » peut apparaître avant la première copie ;
- le travail « Backup » est en cours ou terminé. Il peut durer un moment : ne bloquez pas la fin de séance, revérifiez le J4 au matin.

Regardez les protections du coffre (lecture seule) : coffre `rsv-<PREFIXE>`, **Properties**. **Soft delete** : activé par défaut, 14 jours. **Immutable vault** : **laissez à « Disabled »**. Ne choisissez **jamais** « Enabled and locked » : ce verrouillage est irréversible, et tout doit être supprimé à la fin de la formation.

### 9. La fiche de coût (rôle Dev)

Demandez à Claude Code :

```text
Combien coûte la machine vm-lagune-01 par mois, et comment l'éteindre ?
Donne les paramètres à saisir dans la calculatrice officielle de prix Azure, sans inventer de prix.
```

Ouvrez la calculatrice officielle : https://azure.microsoft.com/pricing/calculator/. Saisissez : région, système, taille, disque, heures par mois (arrêt automatique compris), sauvegarde, Bastion (SKU choisi).

Créez `docs/fiche-cout-vm.md` dans votre dossier `lagune-ops` (`Set-Location $HOME\lagune-ops`, puis `code docs\fiche-cout-vm.md`, Ctrl+S pour enregistrer) avec :

```markdown
# Fiche de coût · vm-lagune-01

| Élément | Paramètre |
|---|---|
| Région | <REGION_FORMATION> |
| Machine | Windows Server, taille <TAILLE_AUTORISEE> |
| Disque | <type et taille> |
| Heures par mois | <nombre> (arrêt automatique à 19:00) |
| Sauvegarde | Coffre Recovery Services, copie quotidienne, 30 jours |
| Bastion | <Developer ou Basic> |

Résultat de la calculatrice officielle : <montant relevé le AAAA-MM-JJ, avec la devise>.
Les prix changent selon la région et le jour : relire avant toute décision.

## Éteindre la machine
- Portail : Virtual machines, vm-lagune-01, Stop (la machine est désallouée).
- Ligne de commande : az vm deallocate --resource-group rg-<PREFIXE>-vm --name vm-lagune-01

## Supprimer
Voir la liste de nettoyage de fin de J4 (04_Labs/README.fr.md).
```

Le montant est celui que **vous** lisez sur la calculatrice, le jour même, avec sa source. Le guide n'en donne aucun.

**Vérifier** : la fiche cite la calculatrice officielle. Vous avez comparé la réponse de Claude avec ce que la calculatrice affiche. Écart ? C'est la calculatrice qui a raison.

### 10. Enregistrer dans le dépôt

```powershell
git switch main
git pull
git switch -c infra/vm-lagune-01
New-Item -ItemType Directory -Force docs | Out-Null
git add docs/fiche-cout-vm.md
git commit -m "Ajoute la fiche de coût de la machine vm-lagune-01"
git push -u origin infra/vm-lagune-01
gh pr create --title "Fiche de coût de vm-lagune-01" --body "Machine sans IP publique, Bastion, arrêt automatique, sauvegarde."
```

Un coéquipier relit : le fichier ne contient ni mot de passe, ni identifiant long.

## Pièges

- **Ouvrir le bureau à distance (port 3389) à tout Internet pour aller plus vite.** Cette porte reste fermée. On passe par Bastion.
- **Une adresse IP publique sur la machine « au cas où ».** Aucune.
- **Un mot de passe dans le dépôt ou dans un message.** Il va dans le coffre de l'équipe.
- **Oublier l'arrêt automatique.** Une machine oubliée est une facture.
- **Croire que le budget arrête les ressources.** Il prévient seulement.
- **Verrouiller le coffre de sauvegarde (« Enabled and locked »).** Irréversible.
- **Laisser Bastion Basic allumé.** Facturé à l'heure dès son déploiement.
- **Bastion Developer, deux machines à la fois.** Il n'en gère qu'une.
- **Un fichier créé après la première sauvegarde.** Il ne sera pas dans la copie du J4 : relancez **Backup now** après l'avoir créé.

## Livrable

- Une machine `vm-lagune-01` sans adresse publique, joignable par Bastion.
- L'arrêt automatique réglé.
- La sauvegarde activée (politique quotidienne) et une première copie lancée.
- La fiche de coût `docs/fiche-cout-vm.md`, fusionnée par demande de fusion.

## Points ouverts

- La disponibilité de Bastion Developer dans la région de formation n'est pas vérifiée : le formateur la contrôle avant la session.
- L'heure de la première sauvegarde et sa durée n'ont pas été mesurées.
- La machine doit être **démarrée** au J4 pour la restauration du fichier : le formateur prévient les équipes.
- La stratégie de taille et de région dépend de la configuration de l'abonnement de formation.
- Aucun prix n'est donné dans ce guide, volontairement.
- La démonstration Ansible du J4 cible cette machine par SSH (OpenSSH actif, depuis une machine du même réseau virtuel). Sa préparation n'est pas décrite ici : décision du formateur.

## Sources

- https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-portal
- https://learn.microsoft.com/en-us/azure/bastion/bastion-overview et https://learn.microsoft.com/en-us/azure/bastion/quickstart-host-portal (Developer : gratuit, une machine à la fois, régions limitées ; Basic : AzureBastionSubnet /26 ou plus)
- https://learn.microsoft.com/en-us/azure/bastion/bastion-sku-comparison (disponibilité régionale)
- https://learn.microsoft.com/en-us/azure/virtual-machines/auto-shutdown-vm
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-first-look-arm (sauvegarde depuis la machine, Backup now)
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-immutable-vault-concept (coffre immuable)
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-security-feature-cloud (suppression douce)
- https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources
- https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview
- https://azure.microsoft.com/pricing/calculator/
- `17_Videos_Jours/sources.md`, lignes A1 ; scripts J3-V06 à J3-V09

*Conception et animation : Yolea, Abidjan.*
