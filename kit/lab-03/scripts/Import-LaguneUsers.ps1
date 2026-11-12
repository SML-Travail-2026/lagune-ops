#Requires -Version 7.2

<#
.SYNOPSIS
    Crée les salariés de Lagune Services à partir d'un fichier CSV (Microsoft Graph PowerShell).

.DESCRIPTION
    Par défaut, le script fait un ESSAI À BLANC : il lit et contrôle le fichier, puis affiche
    ce qu'il ferait, sans rien créer et sans se connecter. Pour créer réellement les comptes,
    ajouter -Apply. Pour un premier essai réel limité, ajouter -First 2.

    Permissions minimales demandées (consentement délégué) :
      User.Create                 créer les comptes
      User.ReadBasic.All          vérifier qu'un compte n'existe pas déjà
      GroupMember.ReadWrite.All   ajouter les comptes au groupe (licence attribuée par groupe)
    Le compte qui se connecte doit avoir au moins le rôle Administrateur des utilisateurs
    (User Administrator).

    Les mots de passe temporaires ne s'affichent jamais à l'écran : ils sont écrits dans
    -HandoverFile, hors du dépôt, et chaque salarié doit en changer à la première connexion.

.EXAMPLE
    ./scripts/Import-LaguneUsers.ps1 -CsvPath ./data/salaries-lagune.csv
    Essai à blanc sur les 20 lignes.

.EXAMPLE
    ./scripts/Import-LaguneUsers.ps1 -CsvPath ./data/salaries-lagune.csv -Apply -First 2
    Essai réel sur 2 comptes seulement.

.EXAMPLE
    ./scripts/Import-LaguneUsers.ps1 -CsvPath ./data/salaries-lagune.csv -Apply -WhatIf
    Connexion réelle, mais chaque création est seulement annoncée (-WhatIf).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CsvPath,

    [ValidatePattern('^[a-z0-9.-]+\.[a-z]{2,}$')]
    [string] $Domain = 'lagune.example',

    [ValidateRange(1, 500)]
    [int] $First,

    [ValidatePattern('^[A-Z]{2}$')]
    [string] $UsageLocation = 'CI',

    [string] $GroupName = 'Lagune-Salaries',

    [string] $HandoverFile = (Join-Path -Path $HOME -ChildPath ("lagune-mots-de-passe-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date))),

    [switch] $Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RequiredColumns = @('Prenom', 'Nom', 'UPN', 'Service', 'Poste', 'Ville')
$Scopes = @('User.Create', 'User.ReadBasic.All', 'GroupMember.ReadWrite.All')

function Get-RandomPassword {
    [CmdletBinding()]
    [OutputType([string])]
    param([int] $Length = 16)

    # Générateur aléatoire cryptographique ; une lettre majuscule, une minuscule,
    # un chiffre et un symbole au minimum (règles de complexité Entra ID).
    $sets = @('ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '23456789', '!#%+-=?@_')
    $all = -join $sets
    $chars = [System.Collections.Generic.List[char]]::new()
    foreach ($set in $sets) {
        $chars.Add($set[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($set.Length)])
    }
    while ($chars.Count -lt $Length) {
        $chars.Add($all[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($all.Length)])
    }
    # Mélange de Fisher-Yates, lui aussi cryptographique.
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $j = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($i + 1)
        $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
    }
    return -join $chars
}

function Test-LaguneRow {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] $Row,
        [Parameter(Mandatory)] [string] $Domain
    )
    $problems = @()
    foreach ($col in $RequiredColumns) {
        if ([string]::IsNullOrWhiteSpace($Row.$col)) { $problems += "colonne $col vide" }
    }
    $upn = [string]$Row.UPN
    if ($upn -notmatch "^[A-Za-z0-9._-]+@$([regex]::Escape($Domain))$") {
        $problems += "UPN '$upn' invalide (lettres sans accent, chiffres, . _ -, domaine $Domain)"
    }
    return $problems
}

# --- 1. Lire et contrôler le fichier (aucune connexion) ----------------------
$rows = @(Import-Csv -LiteralPath $CsvPath -Encoding utf8)
if ($rows.Count -eq 0) { throw "Le fichier $CsvPath est vide." }

$missing = $RequiredColumns | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name }
if ($missing) { throw "Colonnes manquantes : $($missing -join ', ')" }

$errors = @()
$duplicates = $rows | Group-Object -Property UPN | Where-Object Count -gt 1
foreach ($d in $duplicates) { $errors += "UPN en double : $($d.Name)" }
foreach ($row in $rows) {
    foreach ($p in (Test-LaguneRow -Row $row -Domain $Domain)) { $errors += "Ligne $($row.UPN) : $p" }
}
if ($errors) {
    $errors | ForEach-Object { Write-Warning $_ }
    throw "$($errors.Count) erreur(s) dans le fichier : rien n'a été fait."
}

if ($First) { $rows = @($rows | Select-Object -First $First) }
Write-Information "Fichier valide : $($rows.Count) salarié(s) à traiter." -InformationAction Continue

# --- 2. Essai à blanc par défaut ---------------------------------------------
if (-not $Apply) {
    foreach ($row in $rows) {
        Write-Information ("[ESSAI] créerait {0} ({1} {2}, {3}) et l'ajouterait au groupe {4}" -f `
                $row.UPN, $row.Prenom, $row.Nom, $row.Service, $GroupName) -InformationAction Continue
    }
    Write-Information 'Essai à blanc terminé. Ajoutez -Apply pour créer réellement les comptes.' -InformationAction Continue
    return
}

# --- 3. Connexion avec les permissions minimales -----------------------------
foreach ($module in 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Users', 'Microsoft.Graph.Groups') {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        throw "Module $module absent : Install-Module Microsoft.Graph -Scope CurrentUser"
    }
}
Connect-MgGraph -Scopes $Scopes -NoWelcome

$createdCount = 0
$failures = 0
try {
    $group = Get-MgGroup -Filter "displayName eq '$($GroupName.Replace("'", "''"))'" -Property Id, DisplayName
    if (-not $group) { throw "Groupe '$GroupName' introuvable : créez-le d'abord (licence attribuée par groupe)." }
    if (@($group).Count -gt 1) { throw "Plusieurs groupes s'appellent '$GroupName'." }

    foreach ($row in $rows) {
        $upn = [string]$row.UPN
        try {
            # Pas de SilentlyContinue : une erreur 403 ou une limitation doit se voir.
            $existing = Get-MgUser -Filter "userPrincipalName eq '$($upn.Replace("'", "''"))'" -Property Id
            if ($existing) {
                Write-Information "[IGNORÉ] $upn existe déjà." -InformationAction Continue
                continue
            }
            if (-not $PSCmdlet.ShouldProcess($upn, 'Créer le compte et l''ajouter au groupe')) { continue }

            $password = Get-RandomPassword
            $params = @{
                AccountEnabled    = $true
                DisplayName       = "$($row.Prenom) $($row.Nom)"
                GivenName         = $row.Prenom
                Surname           = $row.Nom
                MailNickname      = $upn.Split('@')[0]
                UserPrincipalName = $upn
                Department        = $row.Service
                JobTitle          = $row.Poste
                City              = $row.Ville
                UsageLocation     = $UsageLocation
                PasswordProfile   = @{
                    Password                      = $password
                    ForceChangePasswordNextSignIn = $true
                }
            }
            $user = New-MgUser @params

            # Le mot de passe est écrit TOUT DE SUITE : une erreur plus loin ne doit
            # jamais laisser un compte créé avec un mot de passe inconnu.
            if (-not (Test-Path -LiteralPath $HandoverFile)) {
                New-Item -ItemType File -Path $HandoverFile | Out-Null
                if (-not $IsWindows) { & chmod 600 -- $HandoverFile }
            }
            [pscustomobject]@{ UPN = $upn; MotDePasseTemporaire = $password } |
                Export-Csv -LiteralPath $HandoverFile -Append -NoTypeInformation -Encoding utf8
            $createdCount++

            # Ajout au groupe, avec nouvelles tentatives (délai de réplication d'Entra ID).
            $added = $false
            foreach ($attempt in 1..3) {
                try {
                    New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                        '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
                    }
                    $added = $true
                    break
                }
                catch {
                    if ($attempt -lt 3) { Start-Sleep -Seconds (5 * $attempt) }
                }
            }
            if ($added) {
                Write-Information "[CRÉÉ] $upn ajouté au groupe $GroupName." -InformationAction Continue
            }
            else {
                $failures++
                Write-Warning "[À REPRENDRE] $upn créé, mais pas ajouté au groupe $GroupName : ajoutez-le à la main."
            }
        }
        catch {
            $failures++
            Write-Warning "[ÉCHEC] $upn : $($_.Exception.Message)"
        }
    }
}
finally {
    # --- 4. Bilan : mots de passe dans un fichier hors dépôt, jamais à l'écran ----
    if ($createdCount -gt 0) {
        Write-Information "$createdCount compte(s) créé(s). Mots de passe temporaires dans $HandoverFile (à remettre en main propre, puis supprimer le fichier)." -InformationAction Continue
    }
    if ($failures -gt 0) {
        Write-Warning "$failures ligne(s) à reprendre : voir les avertissements ci-dessus."
    }
    Disconnect-MgGraph | Out-Null
}
