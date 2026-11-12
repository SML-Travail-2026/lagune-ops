# LAB-03 · Twenty employees through a pull request

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** Neither the real creation of accounts, nor the review by Claude in GitHub, nor group-based licence assignment has been run in a real tenant yet.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 2, 13:30 |
| **Duration** | 90 minutes |
| **Video brief** | J2-L03 (see also J2-V05 and J2-V06) |

## Objective

Bring the twenty new Lagune employees in from a CSV file, with a reviewed script. The script first goes through a pull request, reviewed by Claude then by a teammate. It is tried in dry-run mode, then on 2 accounts, then on all 20.

## Roles

| Role | What it does |
|---|---|
| **Dev** | Prepares the branch, opens the pull request, answers the comments. May ask Claude Code to explain the script. |
| **Ops** | Runs the dry run, then 2 accounts, then 20. Checks the accounts in the portal. |
| **Security** | Checks the permissions requested and the absence of clear-text passwords. Approves the pull request. |

## Prerequisites

- LAB-01 and LAB-02 done. This whole lab is done in **PowerShell 7**, in your `lagune-ops` folder (`Set-Location $HOME\lagune-ops`): `$PSVersionTable.PSVersion` starts with `7`. The script starts with `#Requires -Version 7.2`: in Windows PowerShell 5.1 it refuses to start. Type `pwsh` if needed.
- If PowerShell answers that "running scripts is disabled on this system", allow it for this window only: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`. The setting disappears when you close the window.
- Microsoft Graph PowerShell module: `Get-Module -ListAvailable Microsoft.Graph*` is not empty. If it is: `Install-Module Microsoft.Graph -Scope CurrentUser` (answer `Y` to the "PSGallery" question; allow several minutes).
- An account with at least the **User Administrator** role in your training tenant.
- **Prepared by the trainer**:
  - a security group `Lagune-Salaries`, with the licence assigned **by group**;
  - the domain name of your training tenant (for example `<TENANT_DOMAIN>`, shaped like `name.onmicrosoft.com`);
  - the key for the automatic review (secret `ANTHROPIC_API_KEY`): a **capped Anthropic key, for the team**, given by the trainer (never in the public repository); and the Claude GitHub app, installed on your repository.
- The script, the CSV and the review file are already in your repository, in `kit/lab-03/` (written by the trainer): you move them into place.

> **Important: the domain.** The CSV file uses the fictitious domain `lagune.example`. It cannot exist in a real tenant. For the real creation, you use a **local copy** of the CSV with your tenant's domain. The CSV in the pull request stays fictitious.

## Steps

### 1. Add the automatic review first

The review file must be in `main` **before** the pull request that will be reviewed. This is a precaution: some GitHub actions refuse to run if their file does not yet exist on the main branch. This behaviour was not verified here.

Store the key the trainer gave you in the repository secrets (one team member does it). The command asks for the value, masked. Never paste it into the conversation:

```powershell
gh secret set ANTHROPIC_API_KEY
```

A small pull request for the review file:

```powershell
git switch main
git pull
git switch -c ci/relecture-claude
New-Item -ItemType Directory -Force .github\workflows | Out-Null
git mv kit\lab-03\.github\workflows\claude-review.yml .github\workflows\claude-review.yml
git add .github/workflows/claude-review.yml
git commit -m "Ajoute la relecture automatique par Claude"
git push -u origin ci/relecture-claude
gh pr create --title "Ajoute la relecture automatique par Claude" --body "Claude comments on requests that touch data/ or scripts/."
```

A teammate reviews on their computer, with the pull request number (`gh pr list`, `gh pr diff <NUMBER>`, `gh pr review <NUMBER> --approve`), then the author, on their branch, merges: `gh pr merge --merge --delete-branch`.

**Check**: the file `.github/workflows/claude-review.yml` is in `main`. It says the review runs on the paths `data/**` and `scripts/**`.

### 2. Add the CSV and the script on a branch (Dev role)

```powershell
git switch main
git pull
git switch -c feat/import-salaries
New-Item -ItemType Directory -Force data, scripts | Out-Null
git mv kit\lab-03\data\salaries-lagune.csv data\salaries-lagune.csv
git mv kit\lab-03\scripts\Import-LaguneUsers.ps1 scripts\Import-LaguneUsers.ps1
```

Ask Claude Code to explain the script **before** you send it:

```text
Explain scripts/Import-LaguneUsers.ps1 step by step, in plain English.
Which permissions does it request? Where does the temporary password go?
```

Write down the answers. You must be able to say:

- the three permissions: `User.Create`, `User.ReadBasic.All`, `GroupMember.ReadWrite.All`;
- without `-Apply`, nothing is created and no sign-in happens;
- passwords go into a file outside the repository, never on screen.

**Check**: the CSV has 21 lines (a header and 20 employees):

```powershell
(Get-Content data\salaries-lagune.csv).Count
```

### 3. The dry run (Ops role)

No sign-in, nothing is created. The branch is not pushed yet: the dry run is done **on the Dev's computer**, in `lagune-ops`.

```powershell
./scripts/Import-LaguneUsers.ps1 -CsvPath ./data/salaries-lagune.csv
```

**Check**: the script prints "Fichier valide : 20 salarié(s) à traiter.", then 20 lines that start with `[ESSAI]`, then "Essai à blanc terminé".

Cause an error on purpose, on a copy outside the repository:

```powershell
$test = Join-Path $env:TEMP "test-erreur.csv"
(Get-Content .\data\salaries-lagune.csv -Encoding utf8) -replace 'mamadou\.traore@', 'mamadou.traoré@' | Set-Content -Path $test -Encoding utf8
./scripts/Import-LaguneUsers.ps1 -CsvPath $test
```

The script must refuse (UPN with an accent) and say "rien n'a été fait" (nothing was done). A user name must not hold an accent.

### 4. The pull request (Dev role)

```powershell
git add data/salaries-lagune.csv scripts/Import-LaguneUsers.ps1
git commit -m "Ajoute le CSV des 20 salariés et le script d'import"
git push -u origin feat/import-salaries
gh pr create --title "Import des 20 salariés de Lagune" --body "Fictitious CSV (lagune.example) and Microsoft Graph PowerShell script. Dry run by default, -Apply -First 2 for a real trial."
```

**Check**: on the request page, the **Checks** (or **Actions**) tab shows the "Relecture par Claude" run. After a few minutes, Claude leaves an opinion and maybe comments on lines.

### 5. Read Claude's review, then the teammate's (Dev and Security roles)

1. Read each Claude comment. For each, decide: right (you fix it) or wrong (you reply, with a reason).
2. Claude **comments**, it does not decide. Its opinion does not replace a human's.
3. The **Security** role reviews with this list:
   - [ ] Microsoft Graph PowerShell only (no MSOnline, no AzureAD);
   - [ ] three permissions, no more;
   - [ ] dry run by default;
   - [ ] no password written in the script or the CSV;
   - [ ] no real data in the CSV.
4. The teammate approves, on their computer, with the pull request number:

```powershell
gh pr list
gh pr view <NUMBER>
gh pr diff <NUMBER>
gh pr review <NUMBER> --approve --body "Reviewed: minimal permissions, dry run by default."
```

Then the author (Dev role), on their branch, merges:

```powershell
gh pr merge --merge --delete-branch
git switch main
git pull
```

**Check**: the request is merged. It has an opinion from Claude **and** a human approval.

### 6. Prepare the CSV for your tenant (Ops role)

On the Ops role's computer, up to date with `main` (after the merge), local copy outside the repository:

```powershell
Set-Location $HOME\lagune-ops
git switch main
git pull
$domaine = "<TENANT_DOMAIN>"
$csv = Join-Path $env:TEMP "salaries-locataire.csv"
(Get-Content .\data\salaries-lagune.csv -Encoding utf8) -replace '@lagune\.example', "@$domaine" | Set-Content -Path $csv -Encoding utf8
```

**Check**: `Get-Content $csv -TotalCount 3` shows addresses that end with your domain.

### 7. Two accounts first (Ops role)

```powershell
./scripts/Import-LaguneUsers.ps1 -CsvPath $csv -Domain $domaine -Apply -First 2
```

A sign-in window opens. It lists the permissions requested: **read it**. It must match the three permissions from step 2. Sign in with your admin account.

The script writes the temporary passwords to a file in your home folder, and prints its name. It does not print them on screen.

**Check**, in the Microsoft 365 or Entra admin center, **Users**:

- the 2 accounts exist (Aya Kouassi, Koffi Yao);
- they are members of the `Lagune-Salaries` group;
- they have their licence (group assignment may take a few minutes: refresh);
- their usage location is `CI`.

Prudence option: `-Apply -WhatIf` really signs in but announces each creation without doing it.

If an account is created but missing from the group, the group may have just been created: a replication delay is possible. Wait a few minutes before running again.

### 8. All twenty (Ops role)

```powershell
./scripts/Import-LaguneUsers.ps1 -CsvPath $csv -Domain $domaine -Apply
```

The 2 accounts already created are skipped (`[IGNORÉ]`). The other 18 are created.

**Check**: the `Lagune-Salaries` group holds 20 members. All 20 have a licence. No password appeared on screen.

### 9. Tidy up

The temporary password file is never read in the conversation with Claude and never committed. In this exercise the accounts are fictitious. Delete the file yourself (Claude is not allowed to delete):

```powershell
Remove-Item -Path $csv
Remove-Item -Path (Join-Path $HOME "lagune-mots-de-passe-*.csv")
```

## Pitfalls

- **Running all twenty at once.** Dry run, then two accounts, then twenty.
- **A user name with an accent or a space.** The script refuses it, on purpose.
- **The fictitious domain.** `lagune.example` does not exist in your tenant: use the trainer's domain for the real creation.
- **A licence that is slow.** Group assignment is not instant. Do not recreate the account.
- **A group that was just created.** The replication delay can make adding a member fail. Wait and run again: existing accounts are skipped.
- **A password in the repository, in a screenshot or in the conversation.** Never.
- **Taking Claude's opinion for an approval.** A human is needed.

## Deliverable

- The pull request "Import des 20 salariés de Lagune", reviewed by Claude and by a teammate, merged.
- The 20 accounts created, members of `Lagune-Salaries`, with their licence.
- A short note in `docs/` (written by the Dev role, validated by the Security role): what Claude flagged, what you fixed, what you refused and why.

## Open points

- The licence required for group-based licence assignment is not stated on the Microsoft page (see `17_Videos_Jours/sources.md`, row M8). The trainer confirms it on the tenant.
- The review by Claude needs a secret and the installation of the Claude GitHub app. They are prepared by the trainer and have not been tried.
- The rule "the review file must already be in `main`" is an unverified precaution.
- On a private repository, mandatory merge checks depend on the GitHub plan (see LAB-01).

## Sources

- https://learn.microsoft.com/en-us/graph/api/user-post-users (`User.Create`, required properties, `New-MgUser`)
- https://learn.microsoft.com/en-us/graph/api/group-post-members (`GroupMember.ReadWrite.All`, `New-MgGroupMemberByRef`, replication delay)
- https://learn.microsoft.com/en-us/powershell/microsoftgraph (Connect-MgGraph)
- https://learn.microsoft.com/en-us/microsoft-365/admin/manage/manage-group-licenses
- https://github.com/anthropics/claude-code-action/blob/v1/docs/solutions.md
- https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
- `17_Videos_Jours/sources.md`, rows M1, M2, M8, G9; starter repository, `kit/lab-03/` folder (`scripts/Import-LaguneUsers.ps1`, `data/salaries-lagune.csv`, `.github/workflows/claude-review.yml`)

*Design and delivery: Yolea, Abidjan.*
