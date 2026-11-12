[Version française](README.fr.md)

# lagune-ops · starter repository for the AZM-201 course

**Day 1:** paste the [starter prompt](docs/prompt-demarrage-J1.en.md) into Claude Code to get your computer ready.

## What is this?

This repository is your team's starting point during the four days of the AZM-201 course. It is about **Lagune Services**, a **fictitious** company in Abidjan. Its domain is `lagune.example`: it does not exist, and all the data in the course is made up.

You never work directly in this template repository. You create **your own copy** of it, for your team.

## Create your team's repository

The team lead first creates the team's free GitHub organisation (on github.com: **+**, **New organization**, **Free**). Then they run this command, replacing `<ORGANISATION>` with the organisation's name (GitHub CLI, `gh`, must be installed and signed in):

```powershell
gh repo create <ORGANISATION>/lagune-ops --template Yolea-Hub/lagune-ops-starter --public --clone
```

The repository is public: that is what makes the required approval before deployment possible (LAB-07). It is created in the team's GitHub organisation and **stays with the team after the course**: it is the team's portfolio. Never put a secret in the repository.

Then that person adds the teammates to the repository, and everyone clones it on their own computer.

## What is at the root, and why

- **`CLAUDE.md`**: the instructions Claude Code reads every time it starts in this repository (fictitious data, no secrets, plan before action, no deletion).
- **`.claude/`**: the workspace rules for Claude Code.
  - `settings.json` says what Claude Code may do without asking.
  - Two automatic rules (`bloquer-secrets.sh` and `bloquer-suppressions.sh`) stop Claude Code if it tries to read a secret file or delete something. They need **`jq`**. On Windows, they run with **Git Bash**.
- **`.gitignore`**: the list of files Git must never record (Terraform state, `.env` files, keys, temporary passwords).
- **`docs/`**: the folder where you keep your reports and screenshots.
- **`kit/`**: ready-to-use files for two labs (see below).
- **`labs/`**: the guides of the eight labs, in French and English. Start with `labs/README.en.md`.

## The `kit/` folder

The files in `kit/` do nothing while they stay there. A lab tells you when to move them into place. You do it **on a branch**, and the files reach `main` through a **pull request** reviewed by a teammate.

The workflows in `kit/` do not run: GitHub only reads `.github/workflows/` at the root of the repository. They start only after being moved there.

- **`kit/lab-03/`**: used in **LAB-03** (importing the 20 employees). It holds the CSV file `data/salaries-lagune.csv`, the script `scripts/Import-LaguneUsers.ps1` and the automatic review `.github/workflows/claude-review.yml`.
- **`kit/lab-07/`**: used in **LAB-07** (the online shop with Terraform and a pipeline). It holds the `terraform/` folder, the pipelines `.github/workflows/deploy.yml` and `destroy.yml`, and the GitLab pipeline `.gitlab-ci.yml`, which **stays in the kit**: the trainer shows it, you do not move it.

The root `.gitignore` is already complete: in LAB-07 you have nothing to add to it.

## The 11 safety rules

1. **Fictitious data only**: `lagune.example`, documentation IP addresses `203.0.113.x`, made-up accounts. Nothing real, neither in the repository nor in the conversation with the AI.
2. **No secret** (password, token, key) in the repository, a screenshot, a log or a conversation with Claude.
3. **The manual gesture first.** The AI proposes, you decide, and you always ask for a source. If you cannot explain a command, you do not approve it.
4. **A plan read before any approval.**
5. **One branch, one pull request, a second pair of eyes.** Never push directly to `main`.
6. **Least privilege**: the smallest permission that is enough.
7. **Never open a port to the Internet** (3389 in particular). Go through Azure Bastion.
8. **No deletion by Claude Code.** A human deletes, after review.
9. **The Juice Shop store is vulnerable on purpose**: it is never open to the whole Internet, only to the classroom's IP address.
10. **Legal framework**: intrusion exercises target only your own shop, with the trainer's written agreement. Attacking a system without permission is a crime (Ivorian law no. 2013-451 of 19 June 2013 on cybercrime).
11. **Trainer's emergency accounts**: they are excluded from the rules, and you do not use them.

---

Design and delivery: Yolea, Abidjan.
