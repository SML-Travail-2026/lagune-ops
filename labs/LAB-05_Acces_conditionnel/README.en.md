# LAB-05 · The conditional access matrix

*Version française : [README.fr.md](README.fr.md)*

> **To be validated on the training tenant before the session.** None of the four policies has been created in a real tenant yet. A lockout risk exists: follow the order of the guide.

| | |
|---|---|
| **Course** | AZM-201 · Administer Microsoft 365 and Azure the DevOps way |
| **When** | Day 3, 10:30 |
| **Duration** | 90 minutes |
| **Video brief** | J3-L05 (see also J3-V03 and J3-V04) |

## Objective

Create Lagune's four conditional access policies in **report-only mode**, test them with the "What If" tool, then turn them on after checking. Then turn off security defaults.

## Roles

| Role | What it does |
|---|---|
| **Security** | Writes the matrix: who, what, from where, with which verification, which exclusions. Checks the two conditions before turning on. |
| **Ops** | Creates the policies in report-only. Tests them with What If. Turns them on. |
| **Dev** | Has Claude Code review the matrix, saves it in the repository. |

## Prerequisites

- **Microsoft Entra ID P1** licence (or Microsoft 365 Business Premium) in your training tenant.
- An account with the **Conditional Access Administrator** role (or Global Administrator). The Entra admin center: https://entra.microsoft.com
- **Prepared by the trainer**:
  - two **emergency access accounts** ("break glass"): cloud-only, in the `.onmicrosoft.com` domain, protected by a physical passkey;
  - a security group `Lagune-Urgence` that holds these two accounts;
  - the **passkey** method allowed in the tenant's authentication methods;
  - the list of countries to block for policy 4: `<BLOCKED_COUNTRIES>`.
- **You do not use the emergency accounts** in this lab. You exclude them, nothing more.
- At least one administrator in the team (your account): they register their passkey in step 3.
- Security defaults are **on** at the start: it is the normal state of a new tenant.

## The four policies

| No. | Policy name | Who | What | Requirement |
|---|---|---|---|---|
| CA01 | `CA01-MFA-tous` | All users, except `Lagune-Urgence` | All resources | Require the authentication strength **Multifactor authentication** |
| CA02 | `CA02-MFA-resistante-admins` | Administration directory roles, except `Lagune-Urgence` | All resources | Require the authentication strength **Phishing-resistant MFA** (passkey) |
| CA03 | `CA03-Bloquer-auth-heritee` | All users, except `Lagune-Urgence` | All resources | **Block** the "Exchange ActiveSync" and "Other clients" clients |
| CA04 | `CA04-Bloquer-pays` | All users, except `Lagune-Urgence` | All resources, from the countries of the named location `Pays-bloques` | **Block** |

All start in **Report-only** mode.

## Steps

### 1. Write the matrix (Security role)

On a branch:

```powershell
git switch main
git pull
git switch -c secu/acces-conditionnel
New-Item -ItemType Directory -Force docs | Out-Null
```

Create `docs/matrice-acces-conditionnel.md` (`code docs\matrice-acces-conditionnel.md`, then Ctrl+S). One row per policy, with **all** these columns. The "Exclusions" column must never be empty:

```markdown
# Conditional access matrix · Lagune

| Policy | Who (included) | Exclusions | Resources | Conditions | Requirement | Starting mode | Risk if badly set |
|---|---|---|---|---|---|---|---|
| CA01-MFA-tous | All users | Group Lagune-Urgence | All | – | MFA strength | Report-only | A user with no MFA method is blocked |
| CA02-MFA-resistante-admins | Administration roles | Group Lagune-Urgence | All | – | Phishing-resistant MFA strength | Report-only | An admin with no passkey is blocked |
| CA03-Bloquer-auth-heritee | All | Group Lagune-Urgence | All | Clients: ActiveSync, other | Block | Report-only | An old application stops working |
| CA04-Bloquer-pays | All | Group Lagune-Urgence | All | Location: Pays-bloques | Block | Report-only | You lock yourself out when travelling, or if the position is detected wrongly |
```

Dev: ask Claude Code to review the matrix.

```text
Review docs/matrice-acces-conditionnel.md. Look for: forgotten exclusions,
policies that could block everyone, including me, and conflicts between policies.
Cite the Microsoft Learn page for each remark.
```

**Check**: the matrix has 4 complete rows. Each Claude remark is accepted or refused in writing.

### 2. Create the named location (Ops role)

For policy 4. Entra center: **Entra ID**, **Conditional Access**, **Named locations**, **Countries location**. Name: `Pays-bloques`. Add the countries from `<BLOCKED_COUNTRIES>`. Never block the country of the classroom, nor the trainer's.

**Check**: the `Pays-bloques` location is in the named locations list. It does not contain your country.

### 3. Administrators register their passkey (Ops and Security roles)

Policy CA02 requires a phishing-resistant method. An administrator without one would be blocked. **This step comes before turning on CA02.**

1. Sign in with your admin account, then open the "My security info" page: https://aka.ms/mysecurityinfo
2. Add a sign-in method of type **passkey**. Follow the wizard (phone or physical key, depending on what the trainer planned).
3. Sign out then sign in again with the key to check that it works.

**Check**: in the Entra center, **Users**, your account, **Authentication methods**: the passkey is listed. Every administrator of the team did the same. Note in the matrix: "Passkeys registered: yes / no for each admin".

### 4. Create the four policies in report-only (Ops role)

Entra center: **Entra ID**, **Conditional Access**, **Policies**, **New policy**. For each policy:

**CA01 · MFA for everyone**

1. Name: `CA01-MFA-tous`.
2. **Users or workload identities**: include **All users**. Exclude **Users and groups**: the `Lagune-Urgence` group.
3. **Target resources**: include **All resources**.
4. **Grant**: **Grant access**, then **Require authentication strength**, and choose **Multifactor authentication**.
5. **Enable policy**: **Report-only**. **Create**.

**CA02 · Phishing-resistant MFA for administrators**

1. Name: `CA02-MFA-resistante-admins`.
2. Users: include **Directory roles**, and pick the administration roles used at Lagune (at least: Global Administrator, User Administrator, License Administrator, Conditional Access Administrator). Exclude the `Lagune-Urgence` group.
3. Resources: **All resources**.
4. **Grant**: **Require authentication strength**, then **Phishing-resistant MFA**.
5. **Report-only**. **Create**.

**CA03 · Block legacy authentication**

1. Name: `CA03-Bloquer-auth-heritee`.
2. Users: all, except `Lagune-Urgence`. Resources: **All resources**.
3. **Conditions**, **Client apps**: **Configure** to **Yes**, tick **only** "Exchange ActiveSync clients" and "Other clients".
4. **Grant**: **Block access**.
5. **Report-only**. **Create**.

**CA04 · Block some countries**

1. Name: `CA04-Bloquer-pays`.
2. Users: all, except `Lagune-Urgence`. Resources: **All resources**.
3. **Conditions**, **Locations**: **Configure** to **Yes**, include the named location `Pays-bloques`.
4. **Grant**: **Block access**.
5. **Report-only**. **Create**.

**Check**: the policy list shows CA01 to CA04, all in **Report-only**. Open each: the `Lagune-Urgence` group is in the exclusions.

> If the portal refuses to create a policy while security defaults are on, write down the exact message and call the trainer. Do not turn off security defaults before step 7.

### 5. Generate sign-ins and read the report (Ops role)

For report-only to have something to read, make a few sign-ins: private browsing window, ordinary LAB-03 accounts, then your admin account.

Wait a few minutes. Entra center: **Entra ID**, **Monitoring & health**, **Sign-in logs**. Open a recent sign-in, **Report-only** tab.

For each policy, note what it **would have done**: applied, not applied, would have blocked, would have required MFA.

**Check**: you found at least one sign-in where CA01 "would have asked" for MFA, and you checked that **nobody unexpected** would have been blocked. A surprise? Fix the policy **before** going on.

### 6. What If (Ops role)

Entra center: **Conditional Access**, **Policies**, **What If** button. Describe an imaginary sign-in, run it, read the list of policies that would apply. Four scenarios:

| Scenario | Expected result |
|---|---|
| An ordinary employee, from the classroom | CA01 applies; CA02 does not |
| An administrator, from the classroom | CA01 and CA02 apply |
| An emergency account | None of the four policies applies |
| An employee from a blocked country | CA04 applies (block) |

For the last scenario, the tool asks for an IP address: the trainer gives you a public address from a country on the list. Documentation addresses (`203.0.113.x`) have no country.

**Check**: the four results match. If the emergency account is affected by a policy, **stop** and fix the exclusion.

### 7. Turn on, then turn off security defaults (Security, Ops roles)

This is the moment of turning on, and not before. First do these five checks aloud, one by one:

1. [ ] The emergency accounts are excluded from all four policies.
2. [ ] Every administrator registered a passkey (step 3) and signed in again with it.
3. [ ] Report-only shows no unexpected block (step 5).
4. [ ] What If gives the expected results (step 6).
5. [ ] Another **admin session stays open** in a different browser, so you can undo in case of error.

Then, in this order, for each policy: **Enable policy** goes from **Report-only** to **On**, then **Save**. Keep **CA02 for last**.

As soon as all four are **On**, turn off security defaults: Entra center, **Entra ID**, **Overview**, **Properties**, **Manage security defaults**, **Disabled**. Choose the reason that says the organisation uses conditional access.

Leave no gap between the two actions: without security defaults and without policies, the tenant is no longer protected.

**Check**, with a private browsing window:

- an ordinary employee signs in and must do MFA (CA01);
- an administrator signs in with their passkey (CA02);
- your session left open in the previous step still works.

**Rollback** if something goes wrong: in the admin session left open, switch the faulty policy back to **Report-only** or **Off**. The emergency account is the last resort, and the trainer is the one who opens it.

### 8. Save (Dev role)

Complete `docs/matrice-acces-conditionnel.md` with a column "Current mode: turned on on <date>" and a section "Report-only results" (2 or 3 lines). No screenshot may show a long identifier.

```powershell
git add docs/matrice-acces-conditionnel.md
git commit -m "Ajoute la matrice d'accès conditionnel et les résultats du rapport seul"
git push -u origin secu/acces-conditionnel
gh pr create --title "Matrice d'accès conditionnel" --body "Four policies, report-only then turn on. Emergency accounts excluded."
```

A teammate reviews and approves.

## Pitfalls

- **Forgetting to exclude the emergency accounts.** They exist for the day a policy blocks everyone.
- **Turning on CA02 before administrators have their passkey.** They would be blocked.
- **Turning on a policy without reading the report-only results.** The report is made for this.
- **Locking yourself out.** Keep another admin session open.
- **Blocking the classroom's country.** Check the `Pays-bloques` list.
- **Leaving a gap between turning on the policies and turning off security defaults.**
- **An administrator reading email with their admin account.** One account dedicated to administration, one ordinary account for daily work.
- **Trusting the location of an IP address blindly.** IP geolocation is sometimes wrong (virtual private networks, operators).

## Deliverable

- `docs/matrice-acces-conditionnel.md` in the repository, merged after review.
- The report-only results (a few lines per policy).
- The four policies **turned on**, security defaults **turned off**.

## Open points

- It is not verified here that the portal accepts to **create** report-only policies while security defaults are on. The Microsoft page only says they must be turned off to use conditional access.
- The exact order of menus on the "Security defaults" screen (Properties, Manage security defaults) is to be confirmed on the tenant.
- The "passkey" method must be allowed by the trainer; its screen name was not verified here.
- To test the country block in What If, the trainer must provide a public IP address from a country on the list.
- Risk-based policies (ID Protection) need the P2 licence: they are not part of this lab.

## Sources

- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength (MFA for everyone, authentication strength, exclusions, report-only)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-report-only
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network (named locations)
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/troubleshoot-conditional-access-what-if
- https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-strengths
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access
- https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults
- `17_Videos_Jours/sources.md`, rows M6, M7; scripts J3-V03 and J3-V04

*Design and delivery: Yolea, Abidjan.*
