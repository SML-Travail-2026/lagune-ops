#!/usr/bin/env bash
# Règle automatique (hook PreToolUse) : bloque la lecture des secrets
# (fichiers .env, variables et état Terraform, clés, mots de passe générés,
# identifiants Azure locaux), par les outils de fichiers comme par le terminal.
# Garde-fou, pas un bac à sable : un script qui ouvre lui-même un fichier n'est pas vu.
set -uo pipefail

refuser() { echo "Bloqué par la règle de l'équipe Lagune : $1" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || refuser "jq est requis pour vérifier cette commande. Installez jq."
entree="$(cat)"
chemins="$(printf '%s' "$entree" | jq -r '[.tool_input.file_path, .tool_input.path, .tool_input.glob] | map(select(. != null)) | join(" ")' 2>/dev/null)" \
  || refuser "entrée du hook illisible."
commande="$(printf '%s' "$entree" | jq -r '.tool_input.command // empty' 2>/dev/null)" \
  || refuser "entrée du hook illisible."

# Fichiers sensibles : cherchés dans les chemins et dans la commande.
fichiers=(
  '(^|[/[:space:]"'"'"'=])\.env([.[:space:]"'"'"']|$)'
  '\.tfvar[s?*]([[:space:]"'"'"'*?]|$)'
  '\.tfstat[e?*]([.[:space:]"'"'"'*?]|$)'
  '\.(pem|pfx|key)([[:space:]"'"'"']|$)'
  'lagune-mots-de-passe'
  '\.azure(/|[[:space:]]|$)'
  'id_(rsa|ed25519)'
)
# Commandes qui affichent des secrets : cherchées dans la commande seulement.
commandes=(
  '(^|[;&|[:space:]])(printenv|env|export[[:space:]]+-p|set)([[:space:]]|$|;|\|)'
  'ARM_[A-Z_]*SECRET|ANTHROPIC_API_KEY|GITHUB_TOKEN|AZURE_ID_TOKEN'
  'az[[:space:]]+account[[:space:]]+get-access-token'
)

# « key=boutique.tfstate » (nom de l'état dans terraform init) n'est pas une lecture.
commande_sans_cle="$(printf '%s' "$commande" | sed -E 's/key=[^[:space:]"'"'"']*//g')"
cible="$chemins $commande_sans_cle"
for motif in "${fichiers[@]}"; do
  if printf '%s' "$cible" | grep -Eiq -- "$motif"; then
    refuser "lecture d'un secret interdite à Claude ($motif). Si vous avez besoin de cette valeur, lisez-la vous-même sans la coller dans la conversation."
  fi
done
if [ -n "$commande" ]; then
  for motif in "${commandes[@]}"; do
    if printf '%s' "$commande" | grep -Eq -- "$motif"; then
      refuser "affichage de secrets interdit à Claude ($motif)."
    fi
  done
fi
exit 0
