# LAB-08 · Game Day « Lagune sous attaque »

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Ce guide est le document **remis aux participants**. Il ne dit ni dans quel ordre ni à quelle heure arrivent les incidents : c'est voulu. La fiche de l'animateur est séparée et ne leur est pas remise.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J4, 15h15 |
| **Durée** | 45 minutes, puis la rétrospective |
| **Brief vidéo** | J4-L08 (voir aussi J4-V09) |

## Objectif

Tenir 45 minutes face à **trois incidents** et remettre Lagune en service. Le formateur n'est plus votre formateur : il est l'incident.

## Les trois incidents

1. Un compte de Lagune est **compromis**.
2. Un fichier important **disparaît** de la machine virtuelle.
3. Toute l'**infrastructure de la boutique** est supprimée.

Vous ne savez ni quand, ni dans quel ordre, ni comment ils arrivent. Vous le découvrez comme dans la vraie vie.

## Rôles

| Rôle | Mission principale |
|---|---|
| **Sécurité** | Traite le compte compromis : bloquer, révoquer, réinitialiser, enquêter. |
| **Ops** | Restaure le fichier depuis la sauvegarde de la nuit. |
| **Dev** | Relance le pipeline pour faire renaître la boutique. |

Les rôles tournent chaque jour : prenez ceux qui ne sont pas les vôtres d'hier. Les trois travaillent en équipe : si un incident vous dépasse, un coéquipier vous aide. Une personne **tient le journal** de l'incident du début à la fin (voir « Livrable »).

## Règles du jeu

1. **Votre périmètre** : votre locataire de formation, votre groupe de ressources, votre dépôt `lagune-ops`. Rien d'autre. Rien chez un autre participant.
2. **Pas de recréation à la main.** La boutique renaît par le **code et le pipeline**, même sous pression. Une ressource créée dans le portail est une faute.
3. **Un plan lu avant toute approbation.** Pas de plan lu, pas d'approbation. La personne qui approuve lit le plan à voix haute.
4. **Claude Code est autorisé comme coéquipier.** Il propose, **l'équipe valide** chaque action, à voix haute : « validé par … ». Si vous ne pouvez pas expliquer une commande, vous ne la validez pas.
5. **Aucun secret** (mot de passe, jeton, clé) dans la conversation avec Claude, dans le dépôt ou dans le journal.
6. **Aucune donnée réelle.** Tout est fictif.
7. **Le formateur a le dernier mot.** S'il dit « STOP EXERCICE », tout le monde arrête.
8. Le Game Day compte pour **30 %** de l'évaluation finale (grille de la fiche de formation).

## Aide-mémoire par rôle

Ce sont des rappels des labs précédents, pas des solutions toutes faites. Lisez avant d'agir.

### Sécurité · le compte compromis

Dans cet ordre :

1. **Bloquer la connexion** du compte (centre d'administration Entra, **Users**, le compte, propriétés, compte désactivé).
2. **Révoquer les sessions ouvertes** : un nouveau mot de passe ne suffit pas toujours à mettre l'attaquant dehors. Avec Microsoft Graph PowerShell (permission `User.RevokeSessions.All`) :

```powershell
Connect-MgGraph -Scopes "User.RevokeSessions.All"
Revoke-MgUserSignInSession -UserId <IDENTIFIANT_OU_UPN>
```

3. **Réinitialiser le mot de passe** (portail), sans l'écrire dans le journal ni dans un message.
4. **Vérifier les méthodes de vérification** du compte (Users, le compte, **Authentication methods**) : l'attaquant a peut-être ajouté son propre téléphone.
5. **Enquêter** : journaux de connexion (**Sign-in logs** : d'où, quand, vers quelles applications), règles de la boîte de messagerie (une règle qui transfère discrètement vers l'extérieur), messages envoyés.
6. Quand tout est propre : débloquer le compte, le rendre à sa propriétaire avec ses méthodes de vérification réenregistrées.

Un rapport d'incident ne contient que ce qui est **prouvé** par un journal.

### Ops · le fichier effacé

1. Portail Azure, la machine `vm-lagune-01`, **Backup**, puis la restauration de **fichiers** (File Recovery).
2. Choisir le **point de restauration** de la nuit (ou celui que vous avez créé avec « Backup now »).
3. Azure fournit un petit programme protégé par un mot de passe. Lancé sur la machine (via Bastion), il ouvre les disques de la sauvegarde en **lecture seule**.
4. Copiez le fichier perdu. Vérifiez son **contenu**.
5. **Démontez les disques** depuis le portail quand c'est fini.

La machine doit être démarrée. Se connecter par Bastion, jamais en ouvrant un port à Internet.

### Dev · la boutique supprimée

1. Regardez le dépôt : le code est intact. C'est lui qui fait renaître la boutique.
2. Lancez le pipeline sur `main` :

```powershell
gh workflow run deploy.yml --ref main
gh run list
gh run watch
```

3. Lisez le plan dans le journal de la tâche « Planifier ». Que doit-il annoncer ? Comparez avec ce que le code décrit. Un plan qui annonce autre chose que des créations est un signal d'arrêt.
4. Un relecteur de l'environnement `production` approuve (pas l'auteur du lancement, si possible). Il n'y a qu'une seule approbation : le scan ZAP suit dans la même tâche.
5. Vérifiez depuis la salle que la boutique répond (`curl.exe -I https://…`). Si le sous-domaine est activé, comptez quelques minutes de plus pour le certificat.

## Pièges

- **Recréer à la main dans le portail, dans la panique.** Passez par le code et le pipeline.
- **Réinitialiser le mot de passe sans révoquer les sessions.** L'attaquant garde sa session.
- **Approuver sans lire le plan.**
- **Laisser Claude Code décider.** Il propose, vous validez.
- **Écrire dans le rapport ce que vous croyez, pas ce que vous avez prouvé.**
- **Oublier de démonter les disques de restauration.**
- **Tout faire seul.** Le rôle compte, l'équipe aussi.

## Livrable

- La **boutique de nouveau en ligne**, à la même adresse, par le pipeline.
- Le **fichier restauré**, avec son contenu vérifié.
- Le **compte repris**.
- Un **rapport d'incident court** dans le dépôt, `incident/rapport-gameday.md`, ouvert par une demande de fusion (relue à la rétrospective). Plan :

```markdown
# Rapport d'incident · Game Day

## Chronologie
| Heure | Ce qu'on a vu | Preuve (journal, capture) |
|---|---|---|

## Actions menées
| Heure | Action | Qui | Validée par |
|---|---|---|---|

## Ce qui a marché / ce qui a coincé

## Leçons : une action à emporter dans votre prochain emploi
```

Pour l'enregistrer (PowerShell 7, dans `lagune-ops`) :

```powershell
git switch main
git pull
git switch -c incident/rapport-gameday
New-Item -ItemType Directory -Force incident | Out-Null
code incident\rapport-gameday.md
git add incident/rapport-gameday.md
git commit -m "Ajoute le rapport d'incident du Game Day"
git push -u origin incident/rapport-gameday
gh pr create --title "Rapport d'incident du Game Day" --body "Chronologie, actions, leçons."
```

Remplissez et enregistrez le fichier dans VS Code (Ctrl+S) **avant** `git add`.

## Rétrospective

Après le Game Day, trois questions, pour toute l'équipe :

1. Qu'est-ce qui a marché ?
2. Qu'est-ce qui a coincé ?
3. Quelle action concrète allez-vous emporter ?

## Points ouverts

- L'environnement du Game Day (le locataire, l'abonnement et le dépôt de quelle personne) est choisi par le formateur.
- Le déroulé de l'après-midi (Game Day, rétrospective, examen, attestations, nettoyage) tient en 75 minutes : le formateur confirme l'horaire.
- Le nom exact des écrans de restauration de fichiers dans le portail Azure n'a pas été vérifié ici. La page de référence est dans les sources.

## Sources

- https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users.actions/revoke-mgusersigninsession (`User.RevokeSessions.All`)
- https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access (révoquer l'accès en urgence)
- https://learn.microsoft.com/en-us/entra/identity/monitoring-health/concept-sign-ins (journaux de connexion)
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-restore-files-from-vm (restaurer des fichiers depuis la sauvegarde d'une machine)
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms (restaurer une machine)
- https://cli.github.com/manual/gh_workflow_run
- `17_Videos_Jours/sources.md`, lignes M4, A1 ; scripts J3-V05, J4-V08, J4-V09 ; `.github/workflows/deploy.yml` de votre dépôt (venu du dépôt modèle)

*Conception et animation : Yolea, Abidjan.*
