# 04_Labs · The eight labs of the AZM-201 course

*Version française : [README.fr.md](README.fr.md)*

Course **AZM-201 · Administer Microsoft 365 and Azure the DevOps way**. Four days, three beginners, in French. Running thread: Lagune Services (a fictitious company, Abidjan, domain `lagune.example`) and its OWASP Juice Shop shop on Azure App Service.

> **To be validated on the training tenant before the session.** None of these guides has been run in a real tenant yet. Commands come from official pages re-read on 5 November 2026 (see `../17_Videos_Jours/sources.md` and the "Sources" section of each guide). Unverified points are stated in the "Open points" section of each guide.

## The labs

| Lab | When | Duration | Folder | What the team produces |
|---|---|---|---|---|
| 1 | Day 1, 13:30 | 60 min | [LAB-01_Depot_lagune-ops](LAB-01_Depot_lagune-ops/README.en.md) | The `lagune-ops` repository on GitHub, its GitLab mirror, the environment map |
| 2 | Day 1, 15:15 | 45 min | [LAB-02_Brancher_Claude_Code](LAB-02_Brancher_Claude_Code/README.en.md) | Claude Code connected to Learn, Azure, GitHub, GitLab; automatic rules tested; hallucination log |
| 3 | Day 2, 13:30 | 90 min | [LAB-03_Import_CSV_par_PR](LAB-03_Import_CSV_par_PR/README.en.md) | 20 employees created by a script reviewed in a pull request |
| 4 | Day 2, 15:15 | 45 min | [LAB-04_Audit_des_roles](LAB-04_Audit_des_roles/README.en.md) | Judged role table, tickets, audit log search |
| 5 | Day 3, 10:30 | 90 min | [LAB-05_Acces_conditionnel](LAB-05_Acces_conditionnel/README.en.md) | Matrix and four conditional access policies, turned on |
| 6 | Day 3, 15:15 | rest of the session | [LAB-06_VM_sauvegardee](LAB-06_VM_sauvegardee/README.en.md) | A VM with no public IP, Bastion, auto-shutdown, backup, cost sheet |
| 7 | Day 4, 08:30 to 12:30 | 4 h | [LAB-07_Terraform_et_pipeline](LAB-07_Terraform_et_pipeline/README.en.md) | The shop online through Terraform and a pipeline, HTTPS, Trivy and ZAP reports |
| 8 | Day 4, 15:15 | 45 min | [LAB-08_Game_Day](LAB-08_Game_Day/README.en.md) | Three incidents, an incident report |


Every guide also exists in French (`README.fr.md`, the main version).

Participants start from the private template repository `Yolea-Hub/lagune-ops-starter` (read access by invitation from the trainer), to create the team's repository in **the team's free GitHub organisation** (`<ORGANISATION>`, for example `lagune-ops-nov2026`). The trainer keeps a private answer key: it is never shared with participants.

## How to read a guide

Each guide gives: the objective, the duration, the roles, the prerequisites, numbered steps with exact commands, a **Check** after each major step, the pitfalls, the deliverable, the open points and the sources.

- The three **roles** (Dev, Ops, Security) rotate every day.
- Words in angle brackets (`<PREFIX>`, `<DOMAIN>`) are values to replace. The trainer gives you the real ones, except `<TEAM_DOMAIN>`: your team's domain name, bought before the course. Replace **the brackets too**: `rg-<PREFIX>-vm` becomes `rg-lagune01-vm`. Left as they are, PowerShell rejects the command ("The '<' operator is reserved for future use").
- Commands are written for **PowerShell 7** on Windows (see "Your computer" below). On macOS or Linux, the `git`, `gh`, `glab`, `az`, `terraform` and `claude` commands are written the same way; PowerShell-specific commands (`Set-Location`, `New-Item`, `$env:...`) get a bash form when useful, labelled "macOS or Linux".
- To **create or edit a file** in the repository (map, log, report), open it in Visual Studio Code from the repository folder: `code docs\carte-environnement.md`. VS Code saves in UTF-8, which keeps accented letters.
- **Reviewing a teammate's pull request**: on your computer you are on `main`, not on their branch. So give the pull request number: `gh pr list`, then `gh pr view <NUMBER>`, `gh pr diff <NUMBER>`, `gh pr review <NUMBER> --approve`.
- All work goes through a **branch** and a **pull request** reviewed by a teammate.

## General prerequisites

- A Windows 10 or 11 computer, 8 GB of memory minimum, install rights.
- The tools from the sheet (section 9): PowerShell 7, Git, Visual Studio Code, Node.js LTS, Azure CLI, Microsoft Graph PowerShell, Terraform, GitHub CLI (`gh`), GitLab CLI (`glab`), Claude Code, Microsoft Authenticator. Each answers to its version command.
- **`jq`** (used by the workspace's automatic rules; on Windows, with Git Bash). It is not in the sheet's list.
- GitHub and GitLab accounts (free). **The team's free GitHub organisation exists before day 1** (created by the team lead, who invites the two teammates and the trainer: see LAB-01 and the pre-course email). Everyone has accepted the GitHub invitation to the template repository `Yolea-Hub/lagune-ops-starter`, received by email from the trainer. Microsoft 365, Azure and Claude accounts are provided.
- A Microsoft 365 training tenant with a Microsoft Entra ID P1 licence (or Business Premium), and an Azure training subscription.

## Your computer: install the tools and open the right terminal

To do before Day 1 (or on D-1 with the trainer). Open **Windows PowerShell** (Start menu), not as administrator, and install with `winget` (the package names are those of the sheet, section 9):

```powershell
winget install Microsoft.PowerShell
winget install Git.Git
winget install Microsoft.VisualStudioCode
winget install OpenJS.NodeJS.LTS
winget install Microsoft.AzureCLI
winget install Hashicorp.Terraform
winget install GitHub.cli
winget install GLab.GLab
winget install jqlang.jq
```

**Git for Windows is not optional in this course.** It provides Git Bash. On Windows, Claude Code runs the repository's automatic rules (`.sh` scripts) with Git Bash; without Git Bash it runs them with PowerShell, and they do not work.

Then **close every terminal window** and open **PowerShell 7**: Start menu, "PowerShell 7", or type `pwsh` in a PowerShell window. It is the terminal for the whole course.

```powershell
$PSVersionTable.PSVersion
git --version; gh --version; glab --version; az --version; terraform -version; node --version; jq --version
Install-Module Microsoft.Graph -Scope CurrentUser
```

**Check**: the PowerShell version starts with `7`; each tool prints a number. `Install-Module` asks whether you trust the "PSGallery" repository: answer `Y`. The install takes several minutes.

Terminal pitfalls:

- **Windows PowerShell 5.1** (blue window, `$PSVersionTable.PSVersion` starts with `5`) is not PowerShell 7. The LAB-03 script refuses to run in 5.1. Type `pwsh` to switch to PowerShell 7.
- A tool you just installed is not found ("is not recognized"): close and reopen the terminal. A window opened before the install does not see the new tool.
- The **Claude app's** terminal: in a session of the **Code** tab, click **Terminal** in the session's title bar, or press **Ctrl+`**. It opens in the session's folder. Check that it is PowerShell 7 (`$PSVersionTable.PSVersion`); if not, type `pwsh`.
- **Where to put your repository**: in your home folder (`$HOME\lagune-ops`, for example `C:\Users\amina\lagune-ops`). Avoid a folder synced by OneDrive (often `Documents` or `Desktop`).

**Prepared by the trainer before the session** (the guides tell you when you check it): group `Lagune-Salaries` with group licence; emergency accounts and group `Lagune-Urgence`; audit role; region and VM size allowed by policy; budget alert; key for the automatic review and the Claude GitHub app; Terraform state storage; federated credentials (OpenID Connect) for the team's repository and the team's prefix; a capped Anthropic key; (the team then creates the GitHub environments `plan`, `production` (required reviewers) and `destruction`, the secrets and the variables, with the IDs given by the trainer); classroom IP address. **Prepared by the team**: its own domain name and access to its DNS zone (see the pre-course email).

## Before day 1 (trainer)

One team of three, one organisation. To do before the first day:

- [ ] Invite each of the three participants to the template repository, read-only (once per `<LOGIN>`):

```powershell
gh api -X PUT repos/Yolea-Hub/lagune-ops-starter/collaborators/<LOGIN> -f permission=pull
```

- [ ] Check the organisation: the trainer is owner (**Owner**) and the `<ORGANISATION>/lagune-ops` repository is **public**.
- [ ] Set the team's prefix (`LAGUNE_PREFIX`, for example `lagune01`).
- [ ] Add the federated credentials (OpenID Connect) for the team's repository in the training tenant, with the trainer script in the answer key.
- [ ] Create one capped Anthropic key for the team (repository secret `ANTHROPIC_API_KEY`).
- [ ] Give the team its IDs (client, tenant, subscription), its prefix and its key, through a private channel. Never in the repository.

## Safety rules

1. **Fictitious data only**: `lagune.example`, documentation IP addresses `203.0.113.x`, invented accounts. No real data, neither in the repositories nor in the conversation with the AI.
2. **No secret** (password, token, key) in a repository, a screenshot, a log or the conversation with Claude. A secret is typed in your terminal, masked, or kept in the team vault.
3. **The manual gesture first. The AI proposes, you decide. Always a source.** If you cannot explain a command, you do not approve it.
4. **A plan read before any approval.** No plan read, no approval.
5. **A branch, a pull request, a second pair of eyes.** Never push straight to `main`.
6. **Least privilege**: the smallest permission that is enough (Microsoft Graph, roles, tokens).
7. **Never open a port to the Internet** (3389 in particular). We use Azure Bastion.
8. **No deletion by Claude Code.** Deletions are done by a human, after review. The workspace's automatic rules block it.
9. **The Juice Shop is deliberately vulnerable**: it is never open to the whole Internet, only to the classroom IP address.
10. **Legal framework**: intrusion exercises target your own shop only, with the trainer's written consent. Attacking a system without authorisation is an offence (Ivorian law no. 2013-451 of 19 June 2013 on the fight against cybercrime).
11. **The trainer's emergency accounts**: we exclude them from policies, we do not use them.

## Common open points

- **Nothing has been run in a real tenant**: OpenID Connect sign-in, real deployment, managed certificate, budget alert, real Graph import, review by Claude, ZAP scan, GitLab pipeline, Ansible demo.
- **Decision of 7 November 2026: one public repository, in the team's free organisation.** On GitHub Free, Pro and Team, required reviewers on an environment exist only for public repositories: the `<ORGANISATION>/lagune-ops` repository is therefore public (with no real data or secret). It stays the team's after the course. Private variant: the GitLab mirror with the manual deploy button (LAB-07). GitLab deployment approvals need the Premium or Ultimate tier.
- **Bastion Developer** (free, one VM at a time) exists only in some regions: to check for the training region.
- **The Ansible demo** targets the day-3 Windows VM over SSH: it needs a VM preparation (OpenSSH) that LAB-06 does not describe.
- Several portal menu names are to be confirmed on the tenant.

## End-of-day-4 cleanup

To do at the end of the session, in this order. **Every deletion is done by a human, after review.** Do not ask Claude Code to delete.

The "Détruire la boutique" (destroy the shop) pipeline deletes **only** what Terraform created (the shop). The day-3 VM, its backup vault and the Terraform state storage are deleted **by hand**.

### 1. Before starting

- [ ] Nobody is connected to the VM through Bastion any more.
- [ ] All reports, screenshots and logs from the labs are in the repositories (pull requests merged).

### 2. The shop: the pipeline destroys the Terraform resources

```powershell
gh workflow run destroy.yml -f confirmation=DETRUIRE
gh run list
gh run watch
```

The "Détruire la boutique" pipeline also reads the destroy plan. Read it: only the shop's resources must appear in it.

- [ ] The run is green.
- [ ] `az group exists --name rg-<PREFIX>-boutique` answers `false`.
- [ ] If `DESTRUCTION_AUTO` is `oui`, the automatic 19:00 destruction will run this evening: the trainer checks tomorrow that the run succeeded (**Actions** tab).

The DNS records (CNAME `boutique` and TXT `asuid.boutique`) are **not** deleted by Terraform:

- [ ] Both records are deleted at the domain host.

### 3. The day-3 VM and its vault: deletion by hand

**Never lock the vault's immutability.** The vault must stay "Disabled" (never "Enabled and locked"), otherwise it can no longer be deleted before the backups expire.

A vault cannot be deleted while it holds backups. Soft delete (14 days by default) keeps deleted backups for 14 days and **blocks** deletion of the vault. So it is turned off before deleting the backups.

In the Azure portal, vault `rsv-<PREFIX>`:

- [ ] **Properties**, **Security Settings**: turn off **Soft Delete** (and **Security Features** if active).
- [ ] **Backup items**, **Azure Virtual Machine**: the machine, **Stop backup**, **Delete Backup Data**, type the machine name (case sensitive), confirm.
- [ ] Check that no item remains in "soft deleted" state (if one does: restore it then delete it again).
- [ ] On the vault **Overview** page: no backup item, no server. Then **Delete** the vault.

Then the VM's resource group (machine, disk, network card, virtual network, network security group, Bastion and its IP address if any remain):

```powershell
az group delete --name rg-<PREFIX>-vm
```

(Answer `y` to the question. Command run by a human.)

- [ ] The vault is deleted.
- [ ] `az group exists --name rg-<PREFIX>-vm` answers `false`.
- [ ] No Bastion Basic or public IP address remains (they are billed by the hour).

If the vault cannot be deleted today (soft delete left on), it will be deletable after 14 days: write down the date and leave an owner. The vault's resource group then stays.

### 4. The Terraform state storage (trainer)

To delete **last**, after all pipelines have ended, by the trainer:

- [ ] The resource group of the state storage account (`TFSTATE_RESOURCE_GROUP`) is deleted.

### 5. Possible leftovers

- [ ] Budgets, alerts and policies set by the trainer on the subscription: the trainer decides whether to keep them.
- [ ] Orphan resources: disks, public IP addresses, network interfaces outside the deleted groups.
- [ ] Groups created automatically by Azure (for example the Network Watcher one): note them, they are empty or managed by Azure.

### 6. Check that everything is empty

```powershell
az group list --query "[].name" --output tsv | ForEach-Object { "$_ : " + (az resource list --resource-group $_ --query "length(@)" --output tsv) }
```

- [ ] Every remaining resource group shows `0`, or is a known, wanted trainer group.
- [ ] The Azure portal, **Cost Management**, shows no running resource.

### 7. Microsoft 365 and Entra (trainer)

- [ ] The 20 fictitious accounts and the conditional access policies: the trainer decides whether to keep or delete them. A deleted account stays restorable for 30 days.
- [ ] The emergency accounts and the `Lagune-Urgence` group: up to the trainer.

### 8. Each participant, on their computer

- [ ] Delete the temporary password files (`lagune-mots-de-passe-*.csv`) and the working CSVs in the temp folder.
- [ ] `Disconnect-MgGraph` and `az logout`.
- [ ] Remove the GitHub server from Claude Code (in the `lagune-ops` folder, where it was added: `Set-Location $HOME\lagune-ops`, then `claude mcp remove github`) and **revoke** the GitHub token created in LAB-02; revoke the GitLab token too if there is one.
- [ ] The repository stays: it is the team's portfolio.

### 9. The trainer, after the course

- [ ] Remove the federated credentials (OpenID Connect) for the team's repository in the training tenant.
- [ ] Revoke the capped Anthropic key.
- [ ] Leave the team's organisation (the repository stays the team's).

### 10. The next day

- [ ] Open **Cost Management** in the Azure portal: costs arrive with a one to two day delay. No new cost must appear.

*Design and delivery: Yolea, Abidjan.*
