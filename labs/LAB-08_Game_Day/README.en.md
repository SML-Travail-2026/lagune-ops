# LAB-08 · Game Day "Lagune under attack"

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** This guide is the document **handed to participants**. It says neither in what order nor at what time the incidents arrive: that is intended. The facilitator sheet is separate and is not handed to them.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 4, 15:15 |
| **Duration** | 45 minutes, then the retrospective |
| **Video brief** | J4-L08 (see also J4-V09) |

## Objective

Hold out for 45 minutes against **three incidents** and put Lagune back in service. The trainer is no longer your trainer: they are the incident.

## The three incidents

1. A Lagune account is **compromised**.
2. An important file **disappears** from the virtual machine.
3. The whole **shop infrastructure** is deleted.

You do not know when, in what order, or how they arrive. You discover them as in real life.

## Roles

| Role | Main mission |
|---|---|
| **Security** | Handles the compromised account: block, revoke, reset, investigate. |
| **Ops** | Restores the file from the night backup. |
| **Dev** | Reruns the pipeline to bring the shop back to life. |

Roles rotate every day: take the ones that were not yours yesterday. The three of you work as a team: if an incident is too much for you, a teammate helps. One person **keeps the log** of the incident from start to finish (see "Deliverable").

## Rules of the game

1. **Your perimeter**: your training tenant, your resource group, your `lagune-ops` repository. Nothing else. Nothing at another participant's.
2. **No recreating by hand.** The shop comes back through the **code and the pipeline**, even under pressure. A resource created in the portal is a fault.
3. **A plan read before any approval.** No plan read, no approval. The person who approves reads the plan aloud.
4. **Claude Code is allowed as a teammate.** It proposes, **the team validates** each action, aloud: "validated by …". If you cannot explain a command, you do not validate it.
5. **No secret** (password, token, key) in the conversation with Claude, in the repository or in the log.
6. **No real data.** Everything is fictitious.
7. **The trainer has the last word.** If they say "STOP EXERCISE", everyone stops.
8. The Game Day counts for **30%** of the final assessment (grid in the course sheet).

## Memory aid by role

These are reminders from the previous labs, not ready-made solutions. Read before you act.

### Security · the compromised account

In this order:

1. **Block sign-in** of the account (Entra admin center, **Users**, the account, properties, account disabled).
2. **Revoke open sessions**: a new password does not always push the attacker out. With Microsoft Graph PowerShell (permission `User.RevokeSessions.All`):

```powershell
Connect-MgGraph -Scopes "User.RevokeSessions.All"
Revoke-MgUserSignInSession -UserId <IDENTIFIER_OR_UPN>
```

3. **Reset the password** (portal), without writing it in the log or in a message.
4. **Check the account's verification methods** (Users, the account, **Authentication methods**): the attacker may have added their own phone.
5. **Investigate**: sign-in logs (**Sign-in logs**: from where, when, to which applications), mailbox rules (a rule that quietly forwards outside), sent messages.
6. When everything is clean: unblock the account, hand it back to its owner with their verification methods registered again.

An incident report contains only what a log **proves**.

### Ops · the deleted file

1. Azure portal, the machine `vm-lagune-01`, **Backup**, then **file** restore (File Recovery).
2. Choose the night's **recovery point** (or the one you created with "Backup now").
3. Azure provides a small program protected by a password. Run on the machine (through Bastion), it opens the backup disks **read-only**.
4. Copy the lost file. Check its **content**.
5. **Unmount the disks** from the portal when done.

The machine must be started. Connect through Bastion, never by opening a port to the Internet.

### Dev · the deleted shop

1. Look at the repository: the code is intact. It is what brings the shop back.
2. Run the pipeline on `main`:

```powershell
gh workflow run deploy.yml --ref main
gh run list
gh run watch
```

3. Read the plan in the log of the "Plan" job. What must it announce? Compare with what the code describes. A plan that announces anything other than creations is a stop signal.
4. A reviewer of the `production` environment approves (not the author of the run, if possible). There is only one approval: the ZAP scan follows in the same job.
5. Check from the classroom that the shop answers (`curl.exe -I https://…`). If the subdomain is on, allow a few more minutes for the certificate.

## Pitfalls

- **Recreating by hand in the portal, in a panic.** Go through the code and the pipeline.
- **Resetting the password without revoking sessions.** The attacker keeps their session.
- **Approving without reading the plan.**
- **Letting Claude Code decide.** It proposes, you validate.
- **Writing in the report what you believe, not what you proved.**
- **Forgetting to unmount the restore disks.**
- **Doing everything alone.** The role matters, and so does the team.

## Deliverable

- The **shop back online**, at the same address, through the pipeline.
- The **file restored**, with its content checked.
- The **account taken back**.
- A **short incident report** in the repository, `incident/rapport-gameday.md`, opened by a pull request (reviewed at the retrospective). Outline:

```markdown
# Incident report · Game Day

## Timeline
| Time | What we saw | Proof (log, screenshot) |
|---|---|---|

## Actions taken
| Time | Action | Who | Validated by |
|---|---|---|---|

## What worked / what jammed

## Lessons: one action to take to your next job
```

To save it (PowerShell 7, in `lagune-ops`):

```powershell
git switch main
git pull
git switch -c incident/rapport-gameday
New-Item -ItemType Directory -Force incident | Out-Null
code incident\rapport-gameday.md
git add incident/rapport-gameday.md
git commit -m "Add the Game Day incident report"
git push -u origin incident/rapport-gameday
gh pr create --title "Game Day incident report" --body "Timeline, actions, lessons."
```

Fill in and save the file in VS Code (Ctrl+S) **before** `git add`.

## Retrospective

After the Game Day, three questions, for the whole team:

1. What worked?
2. What jammed?
3. Which concrete action will you take away?

## Open points

- The Game Day environment (whose tenant, subscription and repository) is chosen by the trainer.
- The afternoon schedule (Game Day, retrospective, exam, certificates, cleanup) fits in 75 minutes: the trainer confirms the timing.
- The exact screen names for file restore in the Azure portal were not verified here. The reference page is in the sources.

## Sources

- https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users.actions/revoke-mgusersigninsession (`User.RevokeSessions.All`)
- https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access (revoke access in an emergency)
- https://learn.microsoft.com/en-us/entra/identity/monitoring-health/concept-sign-ins (sign-in logs)
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-restore-files-from-vm (restore files from a machine backup)
- https://learn.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms (restore a machine)
- https://cli.github.com/manual/gh_workflow_run
- `17_Videos_Jours/sources.md`, rows M4, A1; scripts J3-V05, J4-V08, J4-V09; `.github/workflows/deploy.yml` of your repository (from the starter)

*Design and delivery: Yolea, Abidjan.*
