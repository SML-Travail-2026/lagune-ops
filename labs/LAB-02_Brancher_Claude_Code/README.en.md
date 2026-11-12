# LAB-02 · Connect Claude Code to your tools

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** This guide has not yet been run in a real tenant. The GitLab connection and the automatic rules are the most fragile points.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 1, 15:15 (Claude Code session) |
| **Duration** | 45 minutes |
| **Video brief** | J1-L02 (see also J1-V09 and J1-V10) |

## Objective

Connect your Claude Code to Microsoft Learn, Azure, GitHub and GitLab. Check that the automatic rules of the workspace block a deletion. Then catch the AI making a mistake: find at least one error and fix it.

## Roles

| Role | What it does |
|---|---|
| **Dev** | Adds the MCP servers and checks that they answer. Keeps the hallucination hunt log. |
| **Ops** | Asks Claude Code three questions about Azure and writes down the cited source for each. |
| **Security** | Checks the permissions and the automatic rules of the workspace. Tries a deletion: it must be blocked. |

An MCP server is a standard plug that connects an AI to a tool. Each person connects **their own** Claude Code: the three roles work in parallel, then compare.

## Prerequisites

- LAB-01 done: you have the `lagune-ops` repository on your computer.
- Node.js LTS: `node --version` shows a number.
- Azure CLI signed in: see step 1.
- Claude Code installed and signed in, the app **and** the `claude` command: see step 0.
- The prepared workspace: the `CLAUDE.md` file and the `.claude/` folder are already at the root of your repository (they come from the starter).
- **`jq` installed.** The automatic rules need it. See step 7.

## Steps

### 0. Install Claude Code and sign in (everyone, before the lab)

Each Windows computer has **two** ways to use Claude Code, with the **same** Claude account (provided by the trainer):

- **the Claude app** (**Code** tab): to work day to day, in a window;
- **the `claude` command** in PowerShell: this lab needs it for `claude mcp add` and `claude mcp list`. The app **does not install** that command.

**0a. The Claude app**

1. Download the Windows installer from https://claude.com/download and run it (no administrator rights needed).
2. Open **Claude** from the Start menu and sign in with your training Claude account.
3. Click the **Code** tab at the top of the sidebar (hover over the icons to see their names).
4. Under the prompt box, choose the **Local** environment, then the folder control, **Open folder…**, and open your `lagune-ops` folder (`C:\Users\<you>\lagune-ops`).
5. Find the app's **terminal**: the **Terminal** button in the session's title bar, or **Ctrl+`**. It opens in the `lagune-ops` folder. Type `$PSVersionTable.PSVersion`: if the number starts with `5`, type `pwsh` to switch to PowerShell 7. Every PowerShell command in this lab can be typed here, or in a separate PowerShell 7 window.

**Check**: ask "Summarise this repository's README file." Claude answers from your repository. A message asks you to take a paid plan: tell the trainer (the free plan does not include Claude Code).

**0b. The `claude` command**

Prerequisite: Git for Windows (https://git-scm.com/downloads/win, or `winget install Git.Git`). It provides Git Bash. **It is mandatory in this course**: on Windows, Claude Code runs the automatic rules (hooks) with Git Bash, and with PowerShell when Git Bash is missing; the step 7 rules are bash scripts, which do not run under PowerShell.

In PowerShell (not as administrator; the app's terminal is fine):

```powershell
irm https://claude.ai/install.ps1 | iex
```

Close and reopen the terminal (a window opened before the install does not find `claude`), then:

```powershell
claude --version
Set-Location $HOME\lagune-ops
claude
```

On first launch, `claude` opens the browser: sign in with **the same** Claude account. If the browser does not open, press `c` to copy the sign-in address. The terminal shows `Login successful`: press Enter. To sign in again later, type `/login` in Claude Code.

Claude Code then asks whether you trust this folder: **accept** (you are in your `lagune-ops` repository). Without this, Claude Code ignores the permissions (`allow`) of the `.claude/settings.json` file; the `deny` and `ask` rules stay active. It would ask you for permission at every command. The answer covers the whole repository and is saved in your profile. Do it **once here, in the terminal**: the app's documentation does not say whether the **Code** tab asks this question itself.

**Check**: `claude --version` shows a number. `claude doctor` reports no blocking error.

Servers added with `claude mcp add` (steps 2, 4, 5) are saved in your profile (`$HOME\.claude.json`), which the app also reads. Without the `-s user` option, a server is added only for the folder where you type the command: type them in `lagune-ops`. After steps 2 to 5, open a new session in the **Code** tab and check that the same tools answer there. In the app, plugins (step 3) can also be added with the **+** button, then **Add plugins**. Panel commands (`/mcp`, `/plugin`) may answer "isn't available in this environment" in the **Code** tab: then type them in `claude`, in the terminal.

### 1. Sign in to Azure

```powershell
az login
az account show
```

**Check**: `az account show` shows your training subscription (name and state "Enabled").

### 2. Connect Microsoft Learn (Dev role)

This server is free and needs no account.

```powershell
claude mcp add --transport http microsoft-learn https://learn.microsoft.com/api/mcp
```

**Check**: see step 6 for the list. The `microsoft-learn` server must appear.

### 3. Connect Azure with the Azure Skills extension (Dev role)

Prerequisites: Node.js LTS and the `az login` sign-in done in step 1.

Start `claude` in the terminal, from your `lagune-ops` folder (`Set-Location $HOME\lagune-ops`, then `claude`), then type in the conversation:

```text
/plugin marketplace add microsoft/azure-skills
/plugin install azure@azure-skills
/plugin list
```

Restart Claude Code if the plugin does not appear (`/exit`, then `claude`). Then leave `claude` with `/exit` to get back to PowerShell.

**Check**: `/plugin list` shows `azure@azure-skills`. Then ask in plain language: "List my Azure subscriptions." Claude Code must show your training subscription.

### 4. Connect GitHub (Dev role)

The GitHub server needs an access token. **You** create it, not Claude Code.

1. On GitHub: **Settings**, **Developer settings**, **Personal access tokens**, **Fine-grained tokens**. Create a token limited to the `lagune-ops` repository only, with the shortest lifetime (one week), able to read repositories, issues and pull requests. The trainer tells you whether write access is allowed.
2. In **your** PowerShell terminal (not in the Claude conversation), type it without showing it, then connect the server:

```powershell
$typed = Read-Host -Prompt "GitHub token" -AsSecureString
$env:GITHUB_PAT = [System.Net.NetworkCredential]::new("", $typed).Password
claude mcp add --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer $env:GITHUB_PAT"
Remove-Item Env:GITHUB_PAT
Remove-Variable typed
```

This form works in PowerShell 7 and in Windows PowerShell 5.1 (the `-MaskInput` option only exists since PowerShell 7.1). Type these lines in PowerShell, **not** in `claude`.

macOS or Linux (bash or zsh):

```bash
read -rs GITHUB_PAT
claude mcp add --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer $GITHUB_PAT"
unset GITHUB_PAT
```

If your version of Claude Code refuses this form, the GitHub server page gives the `claude mcp add-json github '{...}'` form for recent versions. Type it in PowerShell 7, not in Windows PowerShell 5.1: version 5.1 strips the double quotes from JSON text passed to a program, and the command fails.

> **Good to know.** Claude Code stores this token in its configuration file, in clear text. That is why the token is limited to one repository and a short lifetime. You revoke it at the end of the course.

**Check**: see step 6.

### 5. Connect GitLab (Dev role)

The official GitLab page describes a built-in MCP server (generally available since GitLab 19.5). The course sheet still speaks of an "experimental" `glab` mode: **re-read the command with the trainer before you run it**.

```powershell
claude mcp add -s user --transport http GitLab https://gitlab.com/api/v4/mcp
```

Then start `claude` in the terminal, type `/mcp`, pick the GitLab server and approve the request in your browser (OAuth sign-in).

If you want to try the server mode of `glab` itself, first see whether it exists in your version:

```powershell
glab mcp --help
```

If the command does not exist, or is marked experimental, note it in your log and move on.

**Check**: see step 6.

### 6. Check the connections

In the terminal:

```powershell
claude mcp list
```

In `claude` (in the terminal; in the **Code** tab the command may not be available):

```text
/mcp
```

Each server shows a state: connected, needs authentication, or failed. Take a **screenshot** of the list: it is a deliverable.

**Check**: `microsoft-learn` is connected. `github` and GitLab are connected or waiting for your approval in the browser. A failed server: re-read the command, do not invent one.

Then ask three questions about Azure (**Ops** role):

1. "What is the difference between a subscription and a resource group?"
2. "What is a network security group?"
3. "What does it mean to deallocate a virtual machine?"

For each answer, write down **the cited source** (page address). Open it and check that the page really says that.

### 7. Test the automatic rules (Security role)

The workspace holds `CLAUDE.md`, permissions (`.claude/settings.json`) and two automatic rules (hooks): one blocks deletions, the other blocks reading secrets.

**Test A, with Claude Code.** In the conversation, ask:

```text
Create a file essai.txt, then delete it with the rm command.
```

The command must be **blocked**, with a message that starts with "Bloqué par la règle de l'équipe Lagune". Also ask it to read a `.env` file: same block.

**Test B, without Claude Code.** You send a fake request to the rule yourself. In PowerShell, in the `lagune-ops` folder. We call Git for Windows' `bash` by its full path: plain `bash` is often not found, or starts the WSL one.

```powershell
$bash = "$env:ProgramFiles\Git\bin\bash.exe"
'{"tool_input":{"command":"rm test.txt"}}' | & $bash .claude/hooks/bloquer-suppressions.sh
$LASTEXITCODE
```

The exit code must be `2` (call blocked). A `0` means the call would go through.

**Control test.** A harmless command must pass:

```powershell
'{"tool_input":{"command":"git status"}}' | & $bash .claude/hooks/bloquer-suppressions.sh
$LASTEXITCODE
```

Expected code: `0`.

macOS or Linux: `echo '{"tool_input":{"command":"rm test.txt"}}' | bash .claude/hooks/bloquer-suppressions.sh; echo $?` (same with `git status`).

> **Watch out for `jq`.** The automatic rules read their input with `jq`. Without `jq`, they block **everything** with the message "jq est requis". You would think the rule works while it is broken: that is why the control test matters. If the message mentions `jq`, install it (`winget install jqlang.jq`), close and reopen the terminal, **quit the Claude app completely and reopen it** (it only reads the PATH at start-up), and start again.

**Check**: test A is blocked, test B gives `2`, the control test gives `0`. Then re-read `.claude/settings.json`: three lists, `allow`, `ask`, `deny`. Say in one sentence what each does.

### 8. The hallucination hunt (whole team)

A hallucination is a wrong answer presented as true. Expected example: an old PowerShell module that Microsoft retired.

1. Ask Claude Code, **without** telling it to use Microsoft Learn: "Give the PowerShell command to list Microsoft 365 users."
2. Look at the answer. If it starts with `Connect-MsolService` (the **MSOnline** module), that is an error: this module is retired.
3. Ask again: "Check on Microsoft Learn and cite the page." The right answer uses **Microsoft Graph PowerShell**:

```powershell
Connect-MgGraph -Scopes "User.ReadBasic.All"
Get-MgUser -Top 5
```

4. Check yourself on the Microsoft Graph "List users" page that the permission cited is the smallest one for reading users. If the page says otherwise, **the page is right**.

If the AI makes no mistake, try another question about something that changes fast: a price, a retirement date, a limit. Your mission is to find at least one error, or to say honestly that you found none.

Create the log on a branch, from PowerShell, in `lagune-ops`:

```powershell
git switch main
git pull
git switch -c docs/journal-hallucinations
code docs\journal-hallucinations.md
```

Copy this outline into the file, fill it in, save (Ctrl+S):

```markdown
# Hallucination hunt log

| Question asked | AI answer (summary) | Source cited | Checked on Microsoft Learn | Verdict | Correction |
|---|---|---|---|---|---|
| List users | Connect-MsolService | none | MSOnline retired in 2025 | Wrong | Connect-MgGraph + Get-MgUser |
```

Then push it and open the pull request, to be reviewed by a teammate (as in LAB-01):

```powershell
git add docs/journal-hallucinations.md
git commit -m "Add the hallucination hunt log"
git push -u origin docs/journal-hallucinations
gh pr create --title "Hallucination hunt log" --body "Questions asked, sources checked, errors found."
```

**Check**: the log holds at least one "Wrong" row with its correction and source, or a row saying no error was found over N questions.

## Pitfalls

- **Accepting a command without reading it.** If you cannot explain it, you do not approve it.
- **Pasting a token into the conversation.** Never. A token is typed in your terminal, masked.
- **Believing the rule works because "everything is blocked".** Without `jq`, everything is. Do the control test.
- **Taking the first answer for the right one.** Ask for the source, open it, compare.
- **Connecting a server with too many rights.** Use a token limited to one repository and a short lifetime.

## Deliverable

- A screenshot of the list of connected servers (`claude mcp list` or `/mcp`).
- The log `docs/journal-hallucinations.md`, with at least one error found and fixed, merged by pull request.
- The result of tests A and B from step 7.

## Open points

- The `glab` MCP server mode could not be verified on an official page while writing (the command page redirects to the GitLab server page). The trainer re-reads `glab mcp --help` before the session.
- The GitHub command form depends on the Claude Code version: the GitHub page gives two forms (recent versions, older versions).
- The automatic rules are `bash` scripts that need `jq`. Neither `jq` nor `bash` is in the tool list of the course sheet (section 9). The starter repository expects `jq` on the computers (on Windows, with Git Bash). Install it or plan it for day minus 1.
- The `/ask` command quoted on the Azure Skills page is the GitHub Copilot CLI one. With Claude Code, ask in plain language.
- Sharing between the `claude` command and the app's **Code** tab (MCP servers in `~/.claude.json`, automatic rules, settings): stated by the documentation, to check on a training computer before the session. If a tool is missing in the app, steps 2 to 8 are done in the terminal.
- The app's documentation does not say whether the **Code** tab asks the "trust this folder" question for a local folder, nor whether `/mcp` and `/plugin` answer there: hence going through `claude` in the terminal. The exact shell of the built-in terminal on Windows is not documented either (hence the `$PSVersionTable` check).
- Participants' Claude account: Pro, Max, Team or Enterprise plan (the free plan has no Claude Code). To create and test on day minus 1.

## Sources

- https://code.claude.com/docs/en/setup (Windows 10 1809+, `irm https://claude.ai/install.ps1 | iex`, Git for Windows, `claude --version`, `claude doctor`), https://code.claude.com/docs/en/desktop-quickstart (app, Code tab, Open folder…, paid plan required), https://code.claude.com/docs/en/authentication (browser sign-in, `/login`), https://code.claude.com/docs/en/desktop (settings shared between the app and the command, built-in **Terminal** / Ctrl+`, panel commands unavailable in the Code tab), https://code.claude.com/docs/en/permissions ("Project allow rules and workspace trust": project `allow` rules wait for the trust answer, `deny` and `ask` do not), https://code.claude.com/docs/en/hooks (on Windows, hooks run by Git Bash, or PowerShell without Git Bash)

- https://code.claude.com/docs/en/mcp (`claude mcp add --transport http`, `--header`, `claude mcp list`, `/mcp`)
- https://learn.microsoft.com/api/mcp (Microsoft Learn endpoint; overview page: https://learn.microsoft.com/training/support/mcp)
- https://learn.microsoft.com/en-us/azure/developer/azure-skills/install (Azure Skills, Node.js LTS, `az login`, `/plugin marketplace add microsoft/azure-skills`, `/plugin install azure@azure-skills`)
- https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-claude.md
- https://docs.gitlab.com/user/model_context_protocol/mcp_server/
- https://code.claude.com/docs/en/hooks (exit code 2 = call blocked) and https://code.claude.com/docs/en/permissions
- https://techcommunity.microsoft.com/blog/identity/-/4364991 (MSOnline and AzureAD retirement)
- https://learn.microsoft.com/en-us/graph/api/user-list (the "List users" page to re-read)
- `17_Videos_Jours/sources.md`, rows L4, M3, C1, C2

*Design and delivery: Yolea, Abidjan.*
