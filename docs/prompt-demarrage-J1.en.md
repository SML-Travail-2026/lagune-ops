# Day 1 starter prompt · paste into Claude Code

*Version française : [prompt-demarrage-J1.fr.md](prompt-demarrage-J1.fr.md)*

Each participant opens the Claude app (**Code** tab, **Local** environment) or types `claude` in PowerShell 7, fills in the four lines in angle brackets, then pastes the whole block. Claude Code gets the computer ready for LAB-01 and LAB-02. It does not do the labs for the team.

Before: the trainer has invited the team lead to the template repository `Yolea-Hub/lagune-ops-starter` (this needs the lead's GitHub username). Teammates do not need it: they join the team's organization.

```text
You are my setup assistant for Day 1 of the AZM-201 course (Yolea, Abidjan). My computer runs Windows. Goal: get my computer ready for LAB-01 and LAB-02, without doing the labs for me.

My details:
- My name: <FIRST LAST>
- My role today: <Dev | Ops | Security>
- I am the team lead: <yes | no>
- The team's GitHub organization: <NAME, or "to create" if I am the team lead and it does not exist yet>

Rules, no exceptions:
1. One step at a time. Before any command that installs or changes something, say in one sentence what it does and wait for my go.
2. Never ask me for a password, token or key; never write one in a file or in the conversation. I type the sign-ins myself (gh auth login, az login, glab auth login) in the terminal: just tell me what to type and what to choose.
3. Delete nothing. Never push to main. Create no access token.
4. Fictitious data only (domain lagune.example).
5. Stop before LAB-01 step 5: the review rule, the environment map, the first pull request and the GitLab mirror are done by hand by the team.
6. If a command fails, show the error and propose one fix, with its source. Do not invent commands.

Steps:
A. Terminal: check it is PowerShell 7 ($PSVersionTable.PSVersion starts with 7). Otherwise, tell me to type pwsh.
B. Tools: check git, gh, glab, az, terraform, node, jq and the Microsoft.Graph module (each one's version). For a missing tool, propose the winget command (Git.Git, GitHub.cli, GLab.GLab, Microsoft.AzureCLI, Hashicorp.Terraform, OpenJS.NodeJS.LTS, jqlang.jq) or "Install-Module Microsoft.Graph -Scope CurrentUser". After an install, remind me to close and reopen the terminal; if jq was just installed, to quit the Claude app completely and reopen it.
C. Git Bash: check that "$env:ProgramFiles\Git\bin\bash.exe" exists (the repository's automatic rules need it).
D. Git identity: ask me which address to use, then git config --global user.name and user.email.
E. GitHub: tell me to type "gh auth login" (GitHub.com, HTTPS, Yes, Login with a web browser), then check with "gh auth status".
F. Template repository (team lead only; a teammate goes straight to G): list my pending invitations (gh api user/repository_invitations). With my go, accept the one for Yolea-Hub/lagune-ops-starter (gh api -X PATCH user/repository_invitations/<id>). If it is not there, stop: I will tell the trainer my GitHub username.
G. Depending on my team role:
   - Team lead: guide me to create the free organization on github.com (I do it in the browser: +, New organization, Free), then invite my two teammates as members and the trainer MELJOESTEIN as Owner (People, Invite member). Then, from $HOME (never a OneDrive folder): gh repo create <ORGANIZATION>/lagune-ops --template Yolea-Hub/lagune-ops-starter --public --clone
   - Teammate: list my organization invitations (gh api "user/memberships/orgs?state=pending"). With my go, accept the team's (gh api -X PATCH user/memberships/orgs/<ORGANIZATION> -f state=active). If the lagune-ops repository does not exist yet, wait for the team lead to create it. Then, from $HOME: gh repo clone <ORGANIZATION>/lagune-ops
H. In $HOME\lagune-ops: check that CLAUDE.md, .claude\settings.json, .claude\hooks and kit exist. Then tell me to open a new Claude session in this folder and accept the trust prompt at first launch: without it, the repository's permissions do not apply.
I. Automatic rules, in PowerShell, from $HOME\lagune-ops:
   '{"tool_input":{"command":"rm test.txt"}}' | & "$env:ProgramFiles\Git\bin\bash.exe" .claude/hooks/bloquer-suppressions.sh ; $LASTEXITCODE   (expected: 2)
   '{"tool_input":{"command":"git status"}}' | & "$env:ProgramFiles\Git\bin\bash.exe" .claude/hooks/bloquer-suppressions.sh ; $LASTEXITCODE   (expected: 0)
   If the message mentions jq, go back to step B.
J. Azure: tell me to type "az login", then check "az account show" (training subscription, state Enabled). Change nothing in Azure.
K. Finish with a table: each check, OK or to do, and what I must report to the trainer.
```

*Design and delivery: Yolea, Abidjan.*
