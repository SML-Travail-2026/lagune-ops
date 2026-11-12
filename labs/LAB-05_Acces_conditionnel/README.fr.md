# LAB-05 · La matrice d'accès conditionnel

*English version: [README.en.md](README.en.md)*

> **À valider sur le locataire de formation avant la session.** Aucune des quatre règles n'a encore été créée dans un vrai locataire. Un risque de blocage existe : suivez l'ordre du guide.

| | |
|---|---|
| **Cours** | AZM-201 · Administrer Microsoft 365 et Azure à la manière DevOps |
| **Moment** | J3, 10h30 |
| **Durée** | 90 minutes |
| **Brief vidéo** | J3-L05 (voir aussi J3-V03 et J3-V04) |

## Objectif

Créer les quatre règles d'accès conditionnel de Lagune en **mode rapport seul**, les tester avec l'outil « What If » (« Et si »), puis les activer après vérification. Désactiver ensuite les paramètres de sécurité par défaut.

## Rôles

| Rôle | Ce qu'il fait |
|---|---|
| **Sécurité** | Écrit la matrice : qui, quoi, depuis où, avec quelle vérification, quelles exclusions. Vérifie les deux conditions avant l'activation. |
| **Ops** | Crée les règles en rapport seul. Les teste avec What If. Les active. |
| **Dev** | Fait relire la matrice par Claude Code, l'enregistre dans le dépôt. |

## Prérequis

- Licence **Microsoft Entra ID P1** (ou Microsoft 365 Business Premium) dans votre locataire de formation.
- Un compte avec le rôle **Administrateur de l'accès conditionnel** (ou général). Le centre d'administration Entra : https://entra.microsoft.com
- **Préparé par le formateur** :
  - deux **comptes d'urgence** (« bris de glace ») : comptes cloud uniquement, dans le domaine `.onmicrosoft.com`, protégés par une clé d'accès physique ;
  - un groupe de sécurité `Lagune-Urgence` qui contient ces deux comptes ;
  - la méthode **clé d'accès (passkey)** autorisée dans les méthodes d'authentification du locataire ;
  - la liste des pays à bloquer pour la règle 4 : `<PAYS_BLOQUES>`.
- **Vous n'utilisez pas les comptes d'urgence** dans ce lab. Vous les excluez, rien de plus.
- Au moins un administrateur dans l'équipe (c'est votre compte) : il enregistre sa clé d'accès à l'étape 3.
- Les paramètres de sécurité par défaut sont **actifs** au départ : c'est l'état normal d'un nouveau locataire.

## Les quatre règles

| N° | Nom de la règle | Qui | Quoi | Exigence |
|---|---|---|---|---|
| CA01 | `CA01-MFA-tous` | Tous les utilisateurs, sauf `Lagune-Urgence` | Toutes les ressources | Exiger la force d'authentification **Authentification multifacteur** |
| CA02 | `CA02-MFA-resistante-admins` | Rôles d'annuaire d'administration, sauf `Lagune-Urgence` | Toutes les ressources | Exiger la force d'authentification **MFA résistante à l'hameçonnage** (clé d'accès) |
| CA03 | `CA03-Bloquer-auth-heritee` | Tous les utilisateurs, sauf `Lagune-Urgence` | Toutes les ressources | **Bloquer** les clients « Exchange ActiveSync » et « Autres clients » |
| CA04 | `CA04-Bloquer-pays` | Tous les utilisateurs, sauf `Lagune-Urgence` | Toutes les ressources, depuis les pays de l'emplacement nommé `Pays-bloques` | **Bloquer** |

Toutes commencent en **Rapport seul** (Report-only).

## Étapes

### 1. Écrire la matrice (rôle Sécurité)

Sur une branche :

```powershell
git switch main
git pull
git switch -c secu/acces-conditionnel
New-Item -ItemType Directory -Force docs | Out-Null
```

Créez `docs/matrice-acces-conditionnel.md` (`code docs\matrice-acces-conditionnel.md`, puis Ctrl+S). Une ligne par règle, avec **toutes** ces colonnes. La colonne « Exclusions » ne doit jamais être vide :

```markdown
# Matrice d'accès conditionnel · Lagune

| Règle | Qui (inclus) | Exclusions | Ressources | Conditions | Exigence | Mode de départ | Risque si mal réglée |
|---|---|---|---|---|---|---|---|
| CA01-MFA-tous | Tous les utilisateurs | Groupe Lagune-Urgence | Toutes | – | Force MFA | Rapport seul | Un utilisateur sans méthode MFA est bloqué |
| CA02-MFA-resistante-admins | Rôles d'administration | Groupe Lagune-Urgence | Toutes | – | Force MFA résistante à l'hameçonnage | Rapport seul | Un admin sans clé d'accès est bloqué |
| CA03-Bloquer-auth-heritee | Tous | Groupe Lagune-Urgence | Toutes | Clients : ActiveSync, autres | Bloquer | Rapport seul | Une application ancienne cesse de fonctionner |
| CA04-Bloquer-pays | Tous | Groupe Lagune-Urgence | Toutes | Emplacement : Pays-bloques | Bloquer | Rapport seul | On se bloque en voyage, ou si la position est mal détectée |
```

Dev : demandez à Claude Code de relire la matrice.

```text
Relis docs/matrice-acces-conditionnel.md. Cherche : les exclusions oubliées,
les règles qui pourraient bloquer tout le monde, y compris moi, et les conflits entre règles.
Cite la page Microsoft Learn pour chaque remarque.
```

**Vérifier** : la matrice a 4 lignes complètes. Chaque remarque de Claude est acceptée ou refusée par écrit.

### 2. Créer l'emplacement nommé (rôle Ops)

Pour la règle 4. Centre Entra : **Entra ID**, **Conditional Access**, **Named locations**, **Countries location**. Nom : `Pays-bloques`. Ajoutez les pays de `<PAYS_BLOQUES>`. Ne bloquez jamais le pays de la salle, ni celui du formateur.

**Vérifier** : l'emplacement `Pays-bloques` figure dans la liste des emplacements nommés. Il ne contient pas votre pays.

### 3. Les administrateurs enregistrent leur clé d'accès (rôles Ops et Sécurité)

La règle CA02 exige une méthode résistante à l'hameçonnage. Un administrateur qui n'en a pas serait bloqué. **Cette étape passe avant l'activation de CA02.**

1. Connectez-vous avec votre compte d'administration, puis ouvrez la page « Mes informations de sécurité » : https://aka.ms/mysecurityinfo
2. Ajoutez une méthode de connexion de type **clé d'accès (passkey)**. Suivez l'assistant (téléphone ou clé physique, selon ce que le formateur a prévu).
3. Déconnectez-vous puis reconnectez-vous avec la clé pour vérifier qu'elle marche.

**Vérifier** : dans le centre Entra, **Users**, votre compte, **Authentication methods** : la clé d'accès est listée. Chaque administrateur de l'équipe a fait de même. Notez dans la matrice : « Clés d'accès enregistrées : oui / non pour chaque admin ».

### 4. Créer les quatre règles en rapport seul (rôle Ops)

Centre Entra : **Entra ID**, **Conditional Access**, **Policies**, **New policy**. Pour chaque règle :

**CA01 · MFA pour tous**

1. Nom : `CA01-MFA-tous`.
2. **Users or workload identities** : inclure **All users**. Exclure **Users and groups** : le groupe `Lagune-Urgence`.
3. **Target resources** : inclure **All resources**.
4. **Grant** : **Grant access**, puis **Require authentication strength**, et choisir **Multifactor authentication**.
5. **Enable policy** : **Report-only**. **Create**.

**CA02 · MFA résistante pour les administrateurs**

1. Nom : `CA02-MFA-resistante-admins`.
2. Utilisateurs : inclure **Directory roles**, et choisir les rôles d'administration utilisés chez Lagune (au minimum : Administrateur général, Administrateur des utilisateurs, Administrateur de licences, Administrateur de l'accès conditionnel). Exclure le groupe `Lagune-Urgence`.
3. Ressources : **All resources**.
4. **Grant** : **Require authentication strength**, puis **Phishing-resistant MFA**.
5. **Report-only**. **Create**.

**CA03 · Bloquer l'authentification héritée**

1. Nom : `CA03-Bloquer-auth-heritee`.
2. Utilisateurs : tous, sauf `Lagune-Urgence`. Ressources : **All resources**.
3. **Conditions**, **Client apps** : **Configure** sur **Yes**, cochez **seulement** « Exchange ActiveSync clients » et « Other clients ».
4. **Grant** : **Block access**.
5. **Report-only**. **Create**.

**CA04 · Bloquer certains pays**

1. Nom : `CA04-Bloquer-pays`.
2. Utilisateurs : tous, sauf `Lagune-Urgence`. Ressources : **All resources**.
3. **Conditions**, **Locations** : **Configure** sur **Yes**, inclure l'emplacement nommé `Pays-bloques`.
4. **Grant** : **Block access**.
5. **Report-only**. **Create**.

**Vérifier** : la liste des règles montre CA01 à CA04, toutes en **Report-only**. Ouvrez chacune : le groupe `Lagune-Urgence` est bien dans les exclusions.

> Si le portail refuse de créer une règle tant que les paramètres de sécurité par défaut sont actifs, notez le message exact et appelez le formateur. Ne désactivez pas les paramètres par défaut avant l'étape 7.

### 5. Générer des connexions et lire le rapport (rôle Ops)

Pour que le rapport seul ait quelque chose à lire, faites quelques connexions : fenêtre de navigation privée, comptes ordinaires du LAB-03, puis votre compte d'administration.

Attendez quelques minutes. Centre Entra : **Entra ID**, **Monitoring & health**, **Sign-in logs**. Ouvrez une connexion récente, onglet **Report-only**.

Pour chaque règle, notez ce qu'elle **aurait fait** : appliquée, non appliquée, aurait bloqué, aurait exigé la MFA.

**Vérifier** : vous avez trouvé au moins une connexion pour laquelle CA01 « aurait demandé » la MFA, et vous avez vérifié que **personne d'inattendu** n'aurait été bloqué. Une surprise ? Corrigez la règle **avant** de continuer.

### 6. What If (rôle Ops)

Centre Entra : **Conditional Access**, **Policies**, bouton **What If**. Décrivez une connexion imaginaire, lancez, lisez la liste des règles qui s'appliqueraient. Quatre scénarios :

| Scénario | Résultat attendu |
|---|---|
| Un salarié ordinaire, depuis la salle | CA01 s'applique ; CA02 non |
| Un administrateur, depuis la salle | CA01 et CA02 s'appliquent |
| Un compte d'urgence | Aucune des quatre règles ne s'applique |
| Un salarié depuis un pays bloqué | CA04 s'applique (bloquer) |

Pour le dernier scénario, l'outil demande une adresse IP : le formateur vous donne une adresse publique d'un pays de la liste. Les adresses de documentation (`203.0.113.x`) n'ont pas de pays.

**Vérifier** : les quatre résultats sont conformes. Si le compte d'urgence est concerné par une règle, **arrêtez** et corrigez l'exclusion.

### 7. Activer, puis désactiver les paramètres par défaut (rôles Sécurité, Ops)

C'est le moment de l'activation, et pas avant. Faites d'abord ces cinq contrôles à voix haute, un par un :

1. [ ] Les comptes d'urgence sont exclus des quatre règles.
2. [ ] Chaque administrateur a enregistré sa clé d'accès (étape 3) et s'est reconnecté avec.
3. [ ] Le rapport seul ne montre aucun blocage inattendu (étape 5).
4. [ ] What If donne les résultats attendus (étape 6).
5. [ ] Une **autre session administrateur reste ouverte** dans un autre navigateur, pour pouvoir annuler en cas d'erreur.

Puis, dans cet ordre, pour chaque règle : **Enable policy** passe de **Report-only** à **On**, puis **Save**. Gardez **CA02 pour la fin**.

Dès que les quatre sont **On**, désactivez les paramètres de sécurité par défaut : centre Entra, **Entra ID**, **Overview**, **Properties**, **Manage security defaults**, **Disabled**. Choisissez le motif qui dit que l'organisation utilise l'accès conditionnel.

Ne laissez pas d'écart entre les deux actions : sans les paramètres par défaut et sans les règles, le locataire n'est plus protégé.

**Vérifier**, avec une fenêtre de navigation privée :

- un salarié ordinaire se connecte et doit faire la MFA (CA01) ;
- un administrateur se connecte avec sa clé d'accès (CA02) ;
- votre session ouverte à l'étape précédente fonctionne toujours.

**Retour arrière** si quelque chose se passe mal : dans la session administrateur restée ouverte, repassez la règle fautive en **Report-only** ou **Off**. Le compte d'urgence est le dernier recours, et c'est le formateur qui l'ouvre.

### 8. Enregistrer (rôle Dev)

Complétez `docs/matrice-acces-conditionnel.md` avec une colonne « Mode actuel : activée le <date> » et une section « Résultats du rapport seul » (2 ou 3 lignes). Aucune capture ne doit montrer d'identifiant long.

```powershell
git add docs/matrice-acces-conditionnel.md
git commit -m "Ajoute la matrice d'accès conditionnel et les résultats du rapport seul"
git push -u origin secu/acces-conditionnel
gh pr create --title "Matrice d'accès conditionnel" --body "Quatre règles, rapport seul puis activation. Comptes d'urgence exclus."
```

Un coéquipier relit et approuve.

## Pièges

- **Oublier d'exclure les comptes d'urgence.** Ils servent le jour où une règle bloque tout le monde.
- **Activer CA02 avant que les administrateurs aient leur clé d'accès.** Ils seraient bloqués.
- **Activer une règle sans lire le rapport seul.** Le rapport est fait pour ça.
- **Se bloquer soi-même.** Gardez une autre session administrateur ouverte.
- **Bloquer le pays de la salle.** Vérifiez la liste de `Pays-bloques`.
- **Laisser un écart entre l'activation des règles et la désactivation des paramètres par défaut.**
- **Un administrateur qui lit ses courriels avec son compte d'administration.** Un compte dédié à l'administration, un compte ordinaire pour le quotidien.
- **Croire la position d'une adresse IP infaillible.** La géolocalisation d'une IP se trompe parfois (réseaux privés virtuels, opérateurs).

## Livrable

- `docs/matrice-acces-conditionnel.md` dans le dépôt, fusionné après relecture.
- Les résultats du rapport seul (quelques lignes par règle).
- Les quatre règles **activées**, les paramètres de sécurité par défaut **désactivés**.

## Points ouverts

- Il n'est pas vérifié ici que le portail accepte de **créer** des règles en rapport seul alors que les paramètres par défaut sont actifs. La page Microsoft dit seulement qu'il faut les désactiver pour utiliser l'accès conditionnel.
- L'ordre exact des menus de l'écran « Security defaults » (Properties, Manage security defaults) est à confirmer sur le locataire.
- La méthode « clé d'accès » doit être autorisée par le formateur ; son nom d'écran n'a pas été vérifié ici.
- Pour tester le blocage par pays dans What If, le formateur doit fournir une adresse IP publique d'un pays de la liste.
- Les stratégies fondées sur le risque (ID Protection) demandent la licence P2 : elles ne font pas partie de ce lab.

## Sources

- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength (MFA pour tous, force d'authentification, exclusions, rapport seul)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-report-only
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network (emplacements nommés)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/troubleshoot-conditional-access-what-if
- https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-strengths
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access
- https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults
- `17_Videos_Jours/sources.md`, lignes M6, M7 ; scripts J3-V03 et J3-V04

*Conception et animation : Yolea, Abidjan.*
