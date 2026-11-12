# LAB-01 · The lagune-ops repository and its mirror

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** This guide has not yet been run in a real tenant, nor on real GitHub and GitLab accounts.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 1, 13:30 (Git, GitHub, GitLab session) |
| **Duration** | 60 minutes |
| **Video brief** | J1-L01 |

## Objective

Create the team repository, `lagune-ops`, on GitHub, then its mirror on GitLab. Enforce the rule "nothing gets in without a second pair of eyes". Write the environment map.

## Roles

| Role | What it does |
|---|---|
| **Dev** | Creates the repository and the first branch. Opens the first pull request. |
| **Ops** | Writes the environment map: tenant, subscription, resource group, the three portals. |
| **Security** | Turns on the one-review-required rule. Reviews the pull request. Checks that no secret is in it. |

Roles rotate every day. Write down who holds which role today.

## Prerequisites

- Your computer is ready (see "Your computer" in [the general guide](../README.en.md)): you work in **PowerShell 7** (`$PSVersionTable.PSVersion` starts with `7`), and `git --version`, `gh --version`, `glab --version`, `az --version` answer.
- A GitHub account and a GitLab account (both free).
- The GitHub invitation to `Yolea-Hub/lagune-ops-starter`, received by email from the trainer: **everyone** in the team accepts it before the lab (without it, the step 2 command fails).
- Your team of three: the **team lead** creates the team's free GitHub organisation (step 1). The other two also have a GitHub account: they review your pull requests.
- An Azure subscription and a Microsoft 365 training tenant, provided by the trainer.

## Steps

### 1. Create the team's GitHub organisation (team lead, before day 1)

The team works in **its own free GitHub organisation**, not in a personal account. The team lead creates it, preferably before day 1:

1. On GitHub: **+** (top right), **New organization**, then the **Free** plan.
2. Name: the team lead's choice, for example `lagune-ops-<SESSION>` (`<SESSION>`: the month of the session, for example `nov2026`). This name replaces `<ORGANISATION>` throughout the course.
3. Invite the two teammates as **members** (step 4) and the trainer as **owner**: **People**, **Invite member**, with the account `<TRAINER_ACCOUNT>` given by the trainer.

**Check**: the page `https://github.com/orgs/<ORGANISATION>/people` lists the trainer (Owner role) and your teammates (or their pending invitation).

### 2. Sign in to GitHub

```powershell
gh auth login
gh auth status
git config --global user.name "Your Name"
git config --global user.email "your.address@example.invalid"
```

`gh auth login` asks a few questions: choose **GitHub.com**, the **HTTPS** protocol, answer **Yes** to "Authenticate Git with your GitHub credentials?", then **Login with a web browser** (a code is shown, to type in the page that opens).

**Check**: `gh auth status` says you are logged in to `github.com`. No password is written in any file.

### 3. Create the repository (Dev role)

The trainer prepared a template repository, `Yolea-Hub/lagune-ops-starter`. The team lead creates the team's copy of it, **in the organisation** and public: it already holds the `CLAUDE.md` file, the `.claude/` folder, a complete `.gitignore` (it stops you from sending a secret or a Terraform state by mistake) and the `kit/` folder, which the next labs use.

The command clones the repository into the folder you are in. First move to your home folder (not a OneDrive folder):

```powershell
Set-Location $HOME
gh repo create <ORGANISATION>/lagune-ops --template Yolea-Hub/lagune-ops-starter --public --clone
Set-Location lagune-ops
```

The repository is now in `$HOME\lagune-ops` (for example `C:\Users\amina\lagune-ops`). The next labs start from this folder: `Set-Location $HOME\lagune-ops`.

> **Why a public repository?** Required reviewers on GitHub environments (used in LAB-07) exist, on GitHub Free, Pro and Team, only for **public** repositories. So your repository is public: it never holds any real data or secret (the `.claude/` rules and the `.gitignore` see to that). The repository stays the team's after the course (your portfolio); the trainer withdraws the Azure access and revokes the keys.

**Check**:

```powershell
gh repo view --web
git remote -v
```

The GitHub page opens. The repository is in the `<ORGANISATION>` organisation and marked **Public**. `git remote -v` shows `origin`.

```powershell
Get-Item CLAUDE.md, kit
```

Both exist: the repository holds `CLAUDE.md` and the `kit/` folder.

### 4. Invite the teammates to the organisation (Dev role)

The teammates are **members of the organisation**: they do not need to be invited to the repository. For each of them:

```powershell
gh api -X PUT orgs/<ORGANISATION>/memberships/<TEAMMATE_ACCOUNT> -f role=member
```

Other way: on GitHub, in the organisation, **People**, then **Invite member**. The teammate accepts the invitation received by email, then clones the repository:

```powershell
Set-Location $HOME
gh repo clone <ORGANISATION>/lagune-ops
Set-Location lagune-ops
```

**Check**: the teammate appears under **People** in the organisation, opens the repository in a browser with no 404 error, and the `lagune-ops` folder exists on their computer after the clone.

### 5. Require a review before any merge (Security role)

In the repository on GitHub: **Settings**, **Branches** (or **Rules**, **Rulesets**), then create a rule for the `main` branch:

- require a pull request before merging;
- require **1** approval.

The exact checkbox names may change: read the screen and pick the box that says "require an approval".

**Check**: try to push straight to `main`.

```powershell
Add-Content -Path README.en.md -Value "test direct"
git commit -am "Essai de poussée directe"
git push origin main
```

GitHub must **refuse**. Then undo your test (a human gesture, not for Claude):

```powershell
git reset --hard origin/main
```

If, on the contrary, GitHub **accepted** the push (the rule is not enforced: for example if the repository is not public), your test is already on `main`: `git reset --hard` does not remove it. Undo it safely with a new commit:

```powershell
git revert HEAD
git push
```

Write in the environment map that the rule is not enforced, and tell the trainer.

> **Known limit.** On a **private** repository, this rule may need a paid account (GitHub Team or Pro). If you cannot find the rule, or if GitHub accepts the direct push, **write it down** and tell the trainer. The team rule still stands: you never push to `main`. But GitHub no longer enforces it.

### 6. Write the environment map (Ops role)

You always work on a branch.

```powershell
git switch -c docs/carte-environnement
New-Item -ItemType Directory -Force docs | Out-Null
```

To read the names of your subscription (changes nothing):

```powershell
az login
az account show --query "{abonnement:name, locataire:tenantId}" --output table
```

Create the file `docs/carte-environnement.md` with this outline, in Visual Studio Code (`code docs\carte-environnement.md`, then save with Ctrl+S). Write the **names**, not the long identifiers:

```markdown
# Lagune environment map

| Item | Value | Where to see it |
|---|---|---|
| Tenant | <TENANT_NAME> | Microsoft Entra admin center |
| Subscription | <SUBSCRIPTION_NAME> | Azure portal, Subscriptions |
| Resource group | rg-<PREFIX>-vm (created in LAB-06) | Azure portal |
| Region | <TRAINING_REGION> | Given by the trainer |

## The three portals

| Portal | Address | What it is for |
|---|---|---|
| Microsoft 365 admin center | https://admin.microsoft.com | Accounts, licences, groups |
| Microsoft Entra admin center | https://entra.microsoft.com | Identities, conditional access, roles |
| Azure portal | https://portal.azure.com | Machines, networks, backups |

## Rules
- No long identifier (GUID), no password in this repository.
- Real values live in the team password vault.
```

**Check**: re-read the file. It contains no password, no long identifier, no key.

### 7. First pull request

```powershell
git add docs/carte-environnement.md
git commit -m "Ajoute la carte de l'environnement"
git push -u origin docs/carte-environnement
gh pr create --title "Ajoute la carte de l'environnement" --body "First map: tenant, subscription, resource group, three portals."
```

The **Security** role (or the invited teammate) reviews, **on their own computer**. They are on `main`, not on the pull request's branch, so they give the pull request number (`gh pr list` shows it, for example `1`).

```powershell
Set-Location $HOME\lagune-ops
gh pr list
gh pr view <NUMBER>
gh pr diff <NUMBER>
gh pr review <NUMBER> --approve --body "Reviewed: no secret."
```

The person who opened the request cannot approve it. That is the point.

Then the author of the request (Dev role), still on their branch, merges:

```powershell
gh pr merge --merge --delete-branch
git switch main
git pull
```

**Check**: `git log --oneline` shows the map commit on `main`. The pull request is marked **Merged** on GitHub.

### 8. The GitLab mirror

1. On GitLab, create an **empty** project: **New project**, then **Create blank project**. Name: `lagune-ops`. Level: **Private**. **Untick** the box that creates a README file. A project that already holds a file refuses your first push.
2. Sign in with `glab`, then add GitLab as a second destination:

```powershell
glab auth login
git remote add gitlab https://gitlab.com/<GITLAB_ACCOUNT>/lagune-ops.git
git push gitlab main
```

If GitLab asks for a password, use a personal access token that **you** create in your GitLab profile, with the `write_repository` right, and paste it at the prompt. Never write it in a command or a file.

**Check**: the GitLab project page shows `README.en.md`, `CLAUDE.md`, `kit` and the `docs` folder. The history is the same as on GitHub.

From now on, after every merge:

```powershell
git switch main
git pull
git push gitlab main
```

The copy does not happen by itself.

## Pitfalls

- **Working straight on `main`.** Always create a branch, even for one line.
- **A GitLab project that is not empty.** You need an empty project, with no README, or `git push gitlab main` is refused.
- **Forgetting to push to GitLab.** The two platforms drift apart. Push to both.
- **A secret in the repository.** Even if removed later, it stays in the history. If it happens, tell the trainer: the secret must be replaced.
- **Approving your own request.** GitHub forbids it. Ask a teammate.
- **The main branch name.** The starter repository uses `main`. If `git branch` shows something else, tell the trainer.

## Deliverable

- The public `<ORGANISATION>/lagune-ops` repository on GitHub, in the team's free organisation, with the one-review-required rule (or the note saying why it could not be turned on).
- The first pull request, reviewed by a teammate and merged.
- The GitLab mirror, with the same history.
- The file `docs/carte-environnement.md` in `main`.

## Open points

- Required reviewers on a GitHub environment exist only for public repositories (Free, Pro and Team plans): that is why the training repository is public, in the team's organisation. After the course it stays the team's (portfolio); the trainer withdraws the Azure access and revokes the keys. On GitLab, merge approvals need the Premium tier: on the mirror, the rule stays a team rule.
- Checkbox names in the GitHub and GitLab screens change often. The trainer's screenshots are the reference.
- The command `gh api -X PUT orgs/.../memberships/...` was re-read on the GitHub REST API reference page (endpoint "Set organization membership for a user", `role` parameter: `member` or `admin`); it emails an invitation to an account that is not yet a member. It requires being an organisation owner. The path through the interface works in all cases.
- The organisation and repository steps have not been tried on real GitHub accounts.

## Sources

- https://cli.github.com/manual/gh_repo_create (options `--template`, `--public`, `--clone`)
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/creating-a-new-organization-from-scratch (create an organisation)
- https://docs.github.com/en/rest/orgs/members#set-organization-membership-for-a-user (invite a member)
- https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment (required reviewers: public repositories on Free, Pro and Team)
- https://git-scm.com/docs/git-remote
- https://docs.gitlab.com/ci/environments/deployment_approvals/ (approvals: Premium and Ultimate)
- `17_Videos_Jours/sources.md`, row G10

*Design and delivery: Yolea, Abidjan.*
