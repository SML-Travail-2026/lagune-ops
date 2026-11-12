[English version](README.en.md)

# lagune-ops · dépôt de départ du cours AZM-201

**Jour 1 :** collez le [prompt de démarrage](docs/prompt-demarrage-J1.fr.md) dans Claude Code pour préparer votre poste.

## De quoi s'agit-il ?

Ce dépôt est le point de départ de votre équipe pendant les quatre jours du cours AZM-201. Il met en scène **Lagune Services**, une entreprise **fictive** d'Abidjan. Son domaine est `lagune.example` : il n'existe pas, et toutes les données du cours sont inventées.

Vous ne travaillez jamais directement dans ce dépôt modèle. Vous en créez **votre propre copie**, pour votre équipe.

## Créer le dépôt de votre équipe

Le chef d'équipe crée d'abord l'organisation GitHub gratuite de l'équipe (sur github.com : **+**, **New organization**, **Free**). Puis il lance cette commande, en remplaçant `<ORGANISATION>` par le nom de l'organisation (il faut avoir installé et connecté GitHub CLI, `gh`) :

```powershell
gh repo create <ORGANISATION>/lagune-ops --template Yolea-Hub/lagune-ops-starter --public --clone
```

Le dépôt est public : c'est ce qui permet l'approbation obligatoire avant le déploiement (LAB-07). Il est créé dans l'organisation GitHub de l'équipe et **reste à l'équipe après le cours** : c'est son portfolio. Ne mettez jamais de secret dans le dépôt.

Ensuite, la personne ajoute ses coéquipiers au dépôt, et chacun le clone sur son poste.

## Ce qu'il y a à la racine, et pourquoi

- **`CLAUDE.md`** : les consignes que Claude Code lit à chaque démarrage dans ce dépôt (données fictives, pas de secret, plan avant action, pas de suppression).
- **`.claude/`** : les règles de l'espace de travail pour Claude Code.
  - `settings.json` dit ce que Claude Code a le droit de faire sans demander.
  - Deux règles automatiques (`bloquer-secrets.sh` et `bloquer-suppressions.sh`) arrêtent Claude Code s'il veut lire un fichier secret ou supprimer quelque chose. Elles ont besoin de **`jq`**. Sous Windows, elles tournent avec **Git Bash**.
- **`.gitignore`** : la liste des fichiers que Git ne doit jamais enregistrer (état Terraform, fichiers `.env`, clés, mots de passe temporaires).
- **`docs/`** : le dossier où vous rangez vos rapports et vos captures.
- **`kit/`** : des fichiers prêts à l'emploi pour deux labs (voir ci-dessous).
- **`labs/`** : les guides des huit labs, en français et en anglais. Commencez par `labs/README.fr.md`.

## Le dossier `kit/`

Les fichiers de `kit/` ne font rien tant qu'ils restent là. Un lab vous dit quand les déplacer à leur place. Vous le faites **sur une branche**, et les fichiers arrivent dans `main` par une **demande de fusion** (pull request) relue par un coéquipier.

Les pipelines (workflows) du dossier `kit/` ne se déclenchent pas : GitHub ne lit que `.github/workflows/` à la racine du dépôt. Ils ne démarrent qu'après avoir été déplacés là.

- **`kit/lab-03/`** : utilisé au **LAB-03** (import des 20 salariés). Il contient le fichier CSV `data/salaries-lagune.csv`, le script `scripts/Import-LaguneUsers.ps1` et la relecture automatique `.github/workflows/claude-review.yml`.
- **`kit/lab-07/`** : utilisé au **LAB-07** (la boutique par Terraform et pipeline). Il contient le dossier `terraform/`, les pipelines `.github/workflows/deploy.yml` et `destroy.yml`, et le pipeline GitLab `.gitlab-ci.yml`, qui **reste dans le kit** : le formateur le montre, vous ne le déplacez pas.

Le `.gitignore` de la racine est déjà complet : au LAB-07, vous n'avez rien à y ajouter.

## Les 11 règles de sécurité

1. **Données fictives seulement** : `lagune.example`, adresses IP `203.0.113.x`, comptes inventés. Rien de réel, ni dans le dépôt, ni dans la conversation avec l'IA.
2. **Aucun secret** (mot de passe, jeton, clé) dans le dépôt, une capture, un journal ou une conversation avec Claude.
3. **Le geste à la main d'abord.** L'IA propose, vous décidez, et vous demandez toujours une source. Si vous ne savez pas expliquer une commande, vous ne la validez pas.
4. **Un plan lu avant toute approbation.**
5. **Une branche, une demande de fusion, un deuxième regard.** Jamais de poussée directe sur `main`.
6. **Moindre privilège** : l'autorisation la plus petite qui suffit.
7. **Ne jamais ouvrir un port à Internet** (le 3389 en particulier). On passe par Azure Bastion.
8. **Pas de suppression par Claude Code.** Un humain supprime, après relecture.
9. **La boutique Juice Shop est volontairement vulnérable** : elle n'est jamais ouverte à tout Internet, seulement à l'adresse IP de la salle.
10. **Cadre légal** : les exercices d'intrusion visent uniquement votre propre boutique, avec l'accord écrit du formateur. Attaquer un système sans autorisation est un délit (loi ivoirienne n° 2013-451 du 19 juin 2013 sur la cybercriminalité).
11. **Comptes d'urgence du formateur** : on les exclut des règles, on ne les utilise pas.

---

Conception et animation : Yolea, Abidjan.
