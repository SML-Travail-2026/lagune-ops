# LAB-07 · The shop through Terraform and the pipeline

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** Nothing in this guide has been run in a real tenant yet: not the OpenID Connect sign-in, not the real deployment, not the issuing of the managed certificate, not the ZAP scan of the live site.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 4, 08:30 to 12:30 (15-minute break in the middle) |
| **Duration** | the morning (4 hours) |
| **Video brief** | J4-L07 (see also J4-V01 to J4-V04) |

## Objective

Put Lagune's shop (OWASP Juice Shop) online with Terraform and the GitHub Actions pipeline. In HTTPS, on a subdomain, and reachable from the classroom only. Read every plan before approving.

In this lab, the code is already in your repository, in the `kit/lab-07/` folder. The trainer wrote it: you move it into place, then you explain it with Claude Code. We invent nothing: same files, same names, same variables.

## Roles

| Role | What it does |
|---|---|
| **Dev** | Moves the lab code into place, understands it with Claude Code, opens the pull request. |
| **Ops** | Reads every plan. Adds the two lines at the domain host. Approves the deployment. |
| **Security** | Checks the access restrictions. Reads the Trivy and OWASP ZAP reports. Has Claude Code check the shop in a browser. |

## Prerequisites

- LAB-01 to LAB-06 done. Every command is typed in **PowerShell 7**, in your `lagune-ops` folder (`Set-Location $HOME\lagune-ops`).
- Terraform installed: `terraform -version` prints a number. If not: `winget install Hashicorp.Terraform`, then close and reopen the terminal.
- **Prepared by the trainer** (once). You do not do it, you **check** it:
  - a storage account for the Terraform state (container `tfstate`);
  - **two** password-free pipeline identities in Azure (OpenID Connect): *lagune-plan*, **read-only**, for the `plan` environment (so a pull request's plan cannot deploy anything), and *lagune-deploy* (Contributor role limited to the training subscription) for `production` and `destruction`;
  - **the federated credentials (OpenID Connect) for your repository `<ORGANISATION>/lagune-ops`**, added by the trainer in the training tenant, and **your prefix and IDs** (client, tenant, subscription), which the trainer gave you;
  - a **public** GitHub repository (with no real data or secret in it), in your team's organisation: on GitHub Free, Pro and Team, required reviewers on an environment exist only for public repositories. See "Open points";
  - in your GitHub repository: the environments `plan`, `production` (with required reviewers) and `destruction`; in **each** environment, the secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (with the identity of that environment), which **the team sets itself** with the IDs from the trainer; the repository secret `ANTHROPIC_API_KEY` (capped key given by the trainer, a single one for the team); the variables `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `ROOM_IP_CIDR`, `LAGUNE_PREFIX`, `CUSTOM_HOSTNAME`, `ENABLE_CUSTOM_DOMAIN` (set to `false`), `BUDGET_CONTACT_EMAIL`, `DESTRUCTION_AUTO`;
  - your team's prefix (`LAGUNE_PREFIX`, for example `lagune01`): the Azure application name is unique worldwide;
  - **your team's** domain name `<TEAM_DOMAIN>`, bought before the course (see the pre-course email), and access to its DNS zone; the shop will answer on `boutique.<TEAM_DOMAIN>`;
  - the classroom's public IP address in `ROOM_IP_CIDR` (format `a.b.c.d/32`).
- Node.js 18 or later for Playwright (`node --version`).

To check what the trainer prepared, without seeing anything secret (the list shows only the secret names):

```powershell
gh secret list --env plan
gh secret list --env production
gh secret list --env destruction
gh variable list
```

**Check**: the three Azure secrets in each of the three environments and the eight variables above are present. Something missing? Tell the trainer, do not create it yourself.

## Steps

### 1. Move the lab code into place (Dev role)

You work on a branch. Move the `terraform/` folder, the two GitHub pipelines from `kit/lab-07/`. The `.gitignore` at the root is already complete: do not touch it.

```powershell
git switch main
git pull
git switch -c infra/boutique-terraform
git mv kit\lab-07\terraform terraform
New-Item -ItemType Directory -Force .github\workflows | Out-Null
git mv kit\lab-07\.github\workflows\deploy.yml .github\workflows\deploy.yml
git mv kit\lab-07\.github\workflows\destroy.yml .github\workflows\destroy.yml
```

**Check**: `Get-ChildItem .\terraform` shows `main.tf`, `variables.tf`, `versions.tf`, `outputs.tf`, `terraform.tfvars.example`, `backend.hcl.example` and `.terraform.lock.hcl`. There is **no** `.terraform` folder and no `*.tfvars` or `*.tfstate` file.

`kit/lab-07/.gitlab-ci.yml` stays in the kit: it is the same pipeline on the GitLab side, shown by the trainer. Moving it would run the pipeline on your GitLab mirror at every push.

### 2. Understand the code before sending it (Dev and Security roles)

Open `terraform/main.tf` with Claude Code:

```text
Explain terraform/main.tf, block by block, in plain English.
Why is the App Service plan B1? What does ip_restriction_default_action = "Deny" do?
What is the expiration tag for? Cite the azurerm provider documentation.
```

You must be able to answer:

- Which resources the code creates (with `enable_custom_domain = false`): a resource group, an App Service plan, a Linux web app, a budget. **Four.**
- Why the image is pinned (`v20.3.0`, never "latest").
- Why access is denied to everyone except `ROOM_IP_CIDR`, including on the admin site (SCM).
- Why `https_only`, TLS 1.2 minimum and FTPS disabled.

**Check**: each team member explained a block aloud. Claude's answers are compared with the azurerm provider page.

### 3. Check locally, without touching Azure (Dev role)

```powershell
Set-Location terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
Set-Location ..
```

No `terraform plan` or `terraform apply` locally: planning and applying happen **only** in the pipeline.

**Check**: `terraform fmt -check` prints nothing (code already well formatted), and `terraform validate` answers `Success! The configuration is valid.`

### 4. Pull request: the pipeline plans (Dev and Ops roles)

```powershell
git add terraform .github
git commit -m "Ajoute la boutique Juice Shop en Terraform et le pipeline"
git push -u origin infra/boutique-terraform
gh pr create --title "La boutique de Lagune en Terraform" --body "Lab code: resource group, B1 plan, Juice Shop app, budget. Access limited to the classroom IP."
```

Follow the pipeline:

```powershell
gh run list
gh run watch
```

On a **pull request**, the pipeline does: **Verify the code** (format, validation, Trivy), then **Plan**. It applies nothing, and a pull request's plan is computed with the **read-only** identity.

The **Ops** role reads the plan in the log:

```powershell
gh run view <RUN_NUMBER> --log
```

Look for the `Plan:` line. With the lab code, you must read **4 to add, 0 to change, 0 to destroy**.

Write the result in a comment on the request. On your computer you are on `main`: give the pull request number (`gh pr list`):

```powershell
gh pr comment <PR_NUMBER> --body "Plan read: 4 to create (resource group, B1 plan, web app, budget), 0 to change, 0 to destroy. As expected."
```

No plan read, no approval.

**Check**: the "Verify the code" and "Plan" jobs are green. The plan matches what you predicted in step 2. A plan that announces a **destruction** nobody expects: stop and find out why.

A teammate reviews and approves:

```powershell
gh pr diff <PR_NUMBER>
gh pr review <PR_NUMBER> --approve --body "Code read, plan read."
```

### 5. Merge, approval and deployment (Ops and Security roles)

```powershell
gh pr merge --merge --delete-branch
git switch main
git pull
gh run list
```

Merging into `main` starts the full pipeline: **Verify**, **Plan**, then **Apply then test (after approval)**. This last job **waits** for a reviewer of the `production` environment.

The designated reviewer (**Ops** role):

1. Opens the run page on GitHub (**Actions**, then the "Déployer la boutique" run).
2. Reads the plan of the "Plan" job one last time.
3. Clicks **Review deployments**, ticks `production`, writes a comment, then **Approve and deploy**.

The pipeline applies **exactly the approved plan**, not a new plan.

**Check**: the "Apply then test" job is green. Then, in the Azure portal or on the command line:

```powershell
az webapp show --resource-group rg-<PREFIX>-boutique --name app-<PREFIX>-boutique --query "{etat:state, hote:defaultHostName}" --output table
```

The state is `Running`. Note the default host name (`app-<PREFIX>-boutique.azurewebsites.net`).

The OWASP ZAP scan (passive) runs in the **same job**, right after the apply: there is **only one approval** for the whole deployment.

### 6. Check access from the classroom and from elsewhere (Security role)

From the classroom computer:

```powershell
curl.exe -I https://app-<PREFIX>-boutique.azurewebsites.net
```

Expected: `HTTP/1.1 200` or `HTTP/2 200`. The first load can be slow (container start).

From a phone on the mobile network (not the classroom Wi-Fi), open the same address. Expected: access **denied** (403 error).

**Check**: the classroom sees the shop, the outside does not. That is exactly the rule wanted: a deliberately vulnerable application must never be open to the whole Internet.

### 7. The subdomain and the certificate, in two steps (Ops role)

**Step 1: the two lines at the domain host** (in your team's account at its DNS provider). In the DNS zone of `<TEAM_DOMAIN>`, create:

| Type | Name | Value |
|---|---|---|
| CNAME | `boutique` | `app-<PREFIX>-boutique.azurewebsites.net` |
| TXT | `asuid.boutique` | the value of the application's "Custom Domain Verification ID" |

The CNAME points **directly** to `azurewebsites.net`, with no hop in between. If your zone is at Cloudflare, set both lines to "DNS only" (grey cloud): behind the proxy, the managed certificate is not issued and the "room only" rule would see Cloudflare's address instead of the room's.

Where to read this value: Azure portal, your application `app-<PREFIX>-boutique`, **Custom domains**, field **Custom Domain Verification ID**. It is not a secret: it is a proof of domain ownership. The trainer can also read it with `terraform output -raw custom_domain_verification_id`, if they have access to the state.

Wait for propagation, then check:

```powershell
Resolve-DnsName -Name boutique.<TEAM_DOMAIN> -Type CNAME
Resolve-DnsName -Name asuid.boutique.<TEAM_DOMAIN> -Type TXT
```

**Check**: both answers show the expected values. **Do not go to the next step before.**

**Step 2: turn on the subdomain through the pipeline.**

```powershell
gh variable set CUSTOM_HOSTNAME --body "boutique.<TEAM_DOMAIN>"
gh variable set ENABLE_CUSTOM_DOMAIN --body "true"
gh workflow run deploy.yml --ref main
gh run list
```

The pipeline plans again. The **Ops** role reads the new plan: it must announce **3 to add** (the name binding, the managed certificate, the certificate binding) and **0 to destroy**. It approves `production` as before.

The managed certificate is free, renews itself, and needs an App Service Basic plan or higher (B1 is fine). Issuing it can take a few minutes.

**Check**, from the classroom:

```powershell
curl.exe -I https://boutique.<TEAM_DOMAIN>
```

Expected: a `200` answer, with no certificate error. In the browser, the HTTPS padlock shows.

### 8. Have Claude Code check the shop (Security role)

Add the Playwright MCP server (Node.js 18 or later), in PowerShell, in `lagune-ops`. The single quotes around the package name are needed: without them, PowerShell reads `@playwright` as a variable ("splatting") and the command breaks.

```powershell
claude mcp add playwright -- npx '@playwright/mcp@latest'
```

macOS or Linux: `claude mcp add playwright -- npx @playwright/mcp@latest`.

Then, in Claude Code (start `claude` in the terminal, or open a new session in the **Code** tab so that it sees the new server):

```text
Open https://boutique.<TEAM_DOMAIN>, check that the page answers, that the title is right and
that the connection is encrypted with no certificate error. Report back a screenshot.
```

Approve each browser tool when Claude Code asks. The browser runs on **your computer**, in the classroom: it passes the access restriction. Launched from home, the same test would be refused, and that is intended.

Copy the screenshot to `docs/captures/boutique.png` (Claude Code tells you where it saved it):

```powershell
New-Item -ItemType Directory -Force docs\captures | Out-Null
Copy-Item -Path "<SCREENSHOT_PATH>" -Destination docs\captures\boutique.png
```

**Check**: Claude Code reported that the page answers and the connection is encrypted. The screenshot shows the shop.

### 9. Read the security reports (Security role)

**Trivy** (analysis of the infrastructure code, before deployment). In the log of the "Verify the code" job:

```powershell
gh run view <RUN_NUMBER> --log
```

The pipeline is set to fail on the `HIGH` and `CRITICAL` levels only. Clean code therefore shows nothing serious.

**OWASP ZAP** (baseline, passive scan of the live site). Download the report:

```powershell
gh run download <RUN_NUMBER> --name rapport-zap --dir rapport-zap
```

Open the `.html` file in the `rapport-zap` folder in a browser. Pick **three alerts**. For each: its risk level, what it means, and an idea of a fix. Ask Claude Code to explain the flaw and the good practice.

Write the summary in `docs/rapport-zap-resume.md`. For each alert to handle, open a ticket:

```powershell
gh issue create --title "ZAP: <alert title>" --body "Level: <level>. Proposed fix: <idea>."
```

The `rapport-zap` folder and the summary hold only data from the demonstration shop.

For the scan, the pipeline opens a **temporary access exception** for the GitHub runner, then removes it at the end whatever happens. Check that it is gone:

```powershell
az webapp config access-restriction show --resource-group rg-<PREFIX>-boutique --name app-<PREFIX>-boutique
```

**Check**: the output holds **no** `zap-runner` rule. The `salle-de-formation` rule remains.

### 10. Save (Dev role)

```powershell
git switch main
git pull
git switch -c docs/rapports-boutique
git add docs
git commit -m "Ajoute la capture de la boutique et le résumé du rapport ZAP"
git push -u origin docs/rapports-boutique
gh pr create --title "Capture et résumé ZAP de la boutique" --body "Playwright screenshot, three ZAP alerts and their tickets."
```

A teammate reviews and approves, as always.

## Trainer demonstrations (outside this lab)

- **GitLab CI/CD**: the `.gitlab-ci.yml` file is the same pipeline on the GitLab side. The trainer shows it; you do not run it.
- **Ansible**: the trainer's Ansible demonstration (not in your repository) configures the **Windows Server VM from day 3** (IIS, `C:\Lagune` folder, home page) over SSH. The VM has no public address: the trainer runs the demonstration from a machine in the same virtual network, with the VM started. This lab **does not depend on it**: do not wait for it and do not run it.

## Pitfalls

- **Applying a plan you have not read.** No plan read, no approval.
- **Turning on `ENABLE_CUSTOM_DOMAIN` before the CNAME and the `asuid` TXT exist.** The deployment fails on the name binding. Set the variable back to `false`, create the DNS lines, wait, try again.
- **Copying the `.terraform` folder or a `*.tfvars` file.** Neither belongs in the repository.
- **Overlooking a "to destroy" line.** A plan that destroys something nobody wanted is a stop signal.
- **Two teams with the same prefix.** The application name already exists elsewhere.
- **Opening the shop to the whole Internet "to test".** Never. If you are blocked, check `ROOM_IP_CIDR`.
- **The classroom IP address changed.** The trainer updates `ROOM_IP_CIDR`, then the pipeline plans again.

## Deliverable

- One complete pipeline run: verify, plan, **approve**, apply, test (ZAP). The approval is visible in the run history.
- The screenshot of the live shop (`docs/captures/boutique.png`).
- The ZAP report summary (`docs/rapport-zap-resume.md`) and its tickets.
- The pull requests, reviewed.

## Open points

- **Public repository, in the team's organisation (decision of 7 November 2026).** On GitHub Free, Pro and Team, required reviewers on an environment exist only for **public repositories**: on a private repository, the deployment approval would disappear. The course therefore uses a **public** repository (with no real data or secret). Private variant: the GitLab mirror with the manual deploy button (see below). GitLab deployment approvals need the Premium or Ultimate tier.
- **Ansible**: the demo targets the day-3 Windows VM over SSH and needs Ansible 2.18 or later, the `ansible.windows` collection (in the trainer's demonstration) and OpenSSH running on the VM. Preparing the VM for SSH is not described in LAB-06: the trainer plans it. This lab does not depend on it.
- **Plan identity**: the solution reads the plan with a read-only identity. Its rights (read, state access, reading the application configuration) have not been tried on a real subscription.
- **Certificate and IP restrictions**: the November 2025 Microsoft page says issuing works despite IP restrictions for a subdomain. A general page still says the opposite for a root domain. To be confirmed in real conditions.
- **`asuid` value**: it is read in the portal. The `az webapp show` command also returns a field of this kind, but its exact name was not verified here.
- **ZAP report**: the exact file names in the `rapport-zap` artifact were not verified.
- **`az webapp config access-restriction show`**: the command was not re-read on its reference page while writing (only `add` and `remove` were).

## Sources

- https://developer.hashicorp.com/terraform/cli/commands (init, fmt, validate, plan, apply)
- https://developer.hashicorp.com/terraform/language/backend/azurerm
- https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app
- https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_managed_certificate
- https://learn.microsoft.com/en-us/azure/app-service/configure-ssl-certificate
- https://learn.microsoft.com/en-us/azure/app-service/app-service-managed-certificate-changes-july-2025
- https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain
- https://learn.microsoft.com/en-us/cli/azure/webapp/config/access-restriction
- https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust
- https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments
- https://github.com/microsoft/playwright-mcp
- https://www.zaproxy.org/docs/docker/baseline-scan/ and https://github.com/zaproxy/action-baseline
- https://github.com/aquasecurity/trivy-action
- https://docs.gitlab.com/ci/cloud_services/azure/ (demonstration)
- `17_Videos_Jours/sources.md`, rows T1 to T14, G1 to G10, L1 to L5, C3; starter repository, `kit/lab-07/` folder (`terraform/`, `.github/workflows/deploy.yml`, `destroy.yml`)

*Design and delivery: Yolea, Abidjan.*
