# LAB-04 · Role audit: who has which role, and is it justified?

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** The role-reading commands and the audit log search have not yet been run in a real tenant.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 2, 15:15 |
| **Duration** | 45 minutes |
| **Video brief** | J2-L04 (see also J2-V07) |

## Objective

Draw up the table of Lagune's administration roles, **read-only**, and judge each line: justified, too broad, or to be removed. Every fix goes through a ticket. Then find in the audit log who did what.

## Roles

| Role | What it does |
|---|---|
| **Ops** | Queries the directory read-only, with Claude Code, and produces the table. |
| **Security** | Judges each line: justified, too broad, to remove. Searches the audit log. |
| **Dev** | Saves the table in the repository. Opens a ticket for each fix. |

## Prerequisites

- LAB-01 to LAB-03 done. PowerShell 7 and Microsoft Graph PowerShell installed. Every command is typed in **PowerShell 7** (`pwsh`), in your `lagune-ops` folder (`Set-Location $HOME\lagune-ops`).
- An account that can **read** roles: the Microsoft page lists *Directory Readers*, *Global Reader* or *Privileged Role Administrator* as the minimal roles. **Global Reader** is enough to read and cannot change anything.
- LAB-03 created the 20 employees: they are the material of the audit.
- **Prepared by the trainer**: to give you something to judge, a few accounts in the tenant hold deliberately questionable roles (for example an intern who is a Global Administrator). The trainer also gives one account the audit role for step 6.
- Rule of the lab: **we change nothing**. No `New-`, `Set-`, `Update-` or `Remove-` command today.

## Steps

### 1. Prepare the branch (Dev role)

```powershell
git switch main
git pull
git switch -c audit/roles
New-Item -ItemType Directory -Force docs | Out-Null
```

### 2. Sign in with a single read permission (Ops role)

The Microsoft page "List unifiedRoleAssignments" lists, from least to most privileged: `RoleManagement.Read.Directory`, then `RoleManagement.Read.All`, then `Directory.Read.All`. Take the first one.

```powershell
Connect-MgGraph -Scopes "RoleManagement.Read.Directory"
```

The sign-in window lists what you allow. Read it: there must be **only reading**.

**Check**: `(Get-MgContext).Scopes` shows `RoleManagement.Read.Directory`.

> **To check yourself.** The page cited covers listing role **assignments**. For listing role **definitions** (the names), re-read the Microsoft page "List roleDefinitions": ask Claude Code with the Microsoft Learn server, and check the permission it cites. It is one more exercise against hallucinations.

### 3. Build the inventory (Ops role)

The role names, then the assignments with the person:

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

If the `Nom` and `Compte` columns are empty, the object received does not hold those fields: ask Claude Code to adapt the command, then **read it** before you run it. It must remain a read command.

Keep a copy outside the repository to work from:

```powershell
$tableau | Sort-Object Role | Export-Csv -Path (Join-Path $env:TEMP "roles-lagune.csv") -NoTypeInformation -Encoding utf8
```

**Check**: the table shows at least one Global Administrator. Every line has a role and a name.

Close the session once the inventory is done:

```powershell
Disconnect-MgGraph
```

> **Limit.** This command lists **active** assignments. "Eligible" roles (PIM, P2 licence) are not here: note in your report that this audit does not cover them.

### 4. Judge each line (Security role)

Create `docs/audit-roles.md` (`code docs\audit-roles.md`, then Ctrl+S to save). For each line of the table, a decision:

```markdown
# Administration role audit · Lagune

Read-only audit, done on <DATE> by <TEAM>.

| Role | Account | Justification given | Verdict | Ticket |
|---|---|---|---|---|
| Global Administrator | <account> | Head of security | Justified | – |
| Global Administrator | <intern account> | None | To remove | #<n> |
| User Administrator | <account> | Creates accounts on arrival | Too broad for its task: a narrower role is enough | #<n> |
```

Only three verdicts:

- **Justified**: the role matches the task.
- **Too broad**: a narrower role would be enough.
- **To remove**: no reason to keep this role.

Benchmarks for judging (Microsoft Learn, Entra role best practices):

- fewer than **five** Global Administrators in the organisation;
- an admin account is only for administering;
- choose the narrowest role that is enough (*User Administrator*, *License Administrator*, *Global Reader*).

You may ask Claude Code to prepare a first proposal of verdicts. **You** decide line by line, and you write the justification yourself. The trainer's emergency accounts are deliberate Global Administrators: note them "justified, emergency account", and do not touch them.

**Check**: every line has a verdict and, if it is not "Justified", a ticket number (next step).

### 5. One ticket per fix (Dev role)

We do not fix during the audit. One ticket per line to fix:

```powershell
gh issue create --title "Remove the Global Administrator role from <intern account>" --body "Role audit: no justification. Verdict: to remove. See docs/audit-roles.md. Fix to be done by an administrator, outside the audit."
```

Copy the ticket number into the table.

**Check**: `gh issue list` shows one ticket per fix. No role changed in the tenant.

Save, then pull request:

```powershell
git add docs/audit-roles.md
git commit -m "Ajoute l'audit des rôles d'administration"
git push -u origin audit/roles
gh pr create --title "Audit des rôles d'administration" --body "Read-only audit. One ticket per fix."
```

A teammate reviews and approves, as in the previous labs, with the pull request number (`gh pr list`, `gh pr diff <NUMBER>`, `gh pr review <NUMBER> --approve`).

### 6. The audit log in Microsoft Purview (Security role)

Question: **who created the LAB-03 accounts, and when?**

1. Open the Microsoft Purview portal: https://purview.microsoft.com
2. Choose the **Audit** solution (if the card does not show: **View all solutions**, then **Audit**).
3. On the **Search** page, set the date range (UTC) to cover LAB-03, pick the user who ran the script, then **Search**.
4. In the results, find the account-creation and group-add activities. Note: date, account, activity.

You need one of the roles **Audit Logs** or **View-Only Audit Logs** in the Purview portal. Without it, the page refuses. The trainer gave it to you; if not, note it as a blocking point.

Good to know:

- the search runs as a job: it may take a few minutes;
- traces of an event usually arrive 60 to 90 minutes after the event, sometimes longer;
- without an E5 licence, traces are kept 180 days.

**Check**: you wrote, in `docs/audit-roles.md`, an "Audit log" section with at least one row (date, who, what). If the search still returns nothing, write that as it is, with the time of the search, and search again later.

## Pitfalls

- **Fixing during the audit.** An audit is read-only. Every fix goes through a ticket.
- **Asking for too many permissions.** `Directory.Read.All` and above all any `ReadWrite` permission are useless here.
- **Letting Claude Code run a command that changes things.** `Set-`, `New-`, `Remove-` commands have no place in this audit. Read every command before you approve.
- **Believing the table is complete.** Eligible roles (PIM) are not in it.
- **Searching the audit log too early.** Traces have a delay.
- **Committing a full export of real accounts.** Here the accounts are fictitious. In real life, the export stays out of the repository.

## Deliverable

- `docs/audit-roles.md` in the repository: the judged table and the "Audit log" section.
- A ticket for each fix.
- The pull request reviewed and merged.

## Open points

- The read permissions were re-read on the role **assignments** page only. The **definitions** page remains to be re-read on the tenant (see step 2).
- The exact shape of the `Principal` object returned by `-ExpandProperty` has not been tried in a tenant.
- The exact name of the account-creation activities in Purview was not verified; the team spots them in the results.
- Portal menus change: the trainer's screenshots are the reference.

## Sources

- https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roleassignments (`RoleManagement.Read.Directory`, `Get-MgRoleManagementDirectoryRoleAssignment`, minimal roles Directory Readers, Global Reader, Privileged Role Administrator)
- https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roledefinitions (to re-read)
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices (best practices, fewer than five Global Administrators)
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference (built-in roles)
- https://learn.microsoft.com/en-us/purview/audit-search (Audit Logs and View-Only Audit Logs roles, retention, delay)
- https://cli.github.com/manual/gh_issue_create
- `17_Videos_Jours/sources.md`; script J2-V07

*Design and delivery: Yolea, Abidjan.*
