#!/usr/bin/env bash
# Règle automatique (hook PreToolUse) : bloque les commandes de suppression.
# Code de sortie 2 = l'appel est refusé et le message est renvoyé à Claude.
# Garde-fou, pas un bac à sable : un humain relit toujours ce qui est lancé.
set -uo pipefail

refuser() { echo "Bloqué par la règle de l'équipe Lagune : $1" >&2; exit 2; }

# Sans jq, ou si l'entrée est illisible, on refuse par prudence
# (tout autre code de sortie laisserait passer l'appel).
command -v jq >/dev/null 2>&1 || refuser "jq est requis pour vérifier cette commande. Installez jq."
entree="$(cat)"
commande="$(printf '%s' "$entree" | jq -r '.tool_input.command // empty' 2>/dev/null)" \
  || refuser "entrée du hook illisible."
[ -z "$commande" ] && exit 0

motifs=(
  '(^|[;&|(`[:space:]])(rm|rmdir|shred|unlink)([[:space:]]|$)'
  'terraform([[:space:]]+-chdir=[^[:space:]]+)?[[:space:]]+(destroy|state[[:space:]]+rm)'
  'terraform.*[[:space:]]-destroy([[:space:]]|$)'
  '(^|[;&|[:space:]])az[[:space:]]+([a-z-]+[[:space:]]+)+delete([[:space:]]|$)'
  'Remove-(Mg|Az|Item)'
  'git[[:space:]]+push([[:space:]].*)?[[:space:]](--force(-with-lease)?|-f)([[:space:]]|$)'
  'git[[:space:]]+push([[:space:]].*)?[[:space:]]--delete([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard'
  'git[[:space:]]+clean([[:space:]].*)?[[:space:]]-[a-zA-Z]*f'
  'gh[[:space:]]+(repo|release)[[:space:]]+delete'
  'glab[[:space:]]+[a-z-]+[[:space:]]+delete'
  'find[[:space:]].*-delete'
)

for motif in "${motifs[@]}"; do
  if printf '%s' "$commande" | grep -Eiq -- "$motif"; then
    refuser "commande de suppression interdite à Claude ($motif). Demandez à un humain de la lancer lui-même, après relecture."
  fi
done
exit 0
