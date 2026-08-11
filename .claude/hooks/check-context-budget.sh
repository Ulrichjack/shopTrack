#!/bin/bash
# Garde-fou de gouvernance du contexte : empêche CLAUDE.md de regrossir.
# Déclenché en PostToolUse sur Edit|Write ; ne réagit qu'aux modifications de CLAUDE.md.

input=$(cat)
echo "$input" | grep -q 'CLAUDE\.md' || exit 0

target="${CLAUDE_PROJECT_DIR:-.}/CLAUDE.md"
[ -f "$target" ] || exit 0

max=120
lines=$(wc -l < "$target" | tr -d ' ')

if [ "$lines" -gt "$max" ]; then
  echo "GOUVERNANCE CONTEXTE : CLAUDE.md fait $lines lignes (budget : $max max)." >&2
  echo "Ne pas laisser grossir ce fichier. Déplacer le contenu détaillé vers un skill (.claude/skills/) ou docs/, et ne garder ici qu'un résumé + pointeur." >&2
  echo "Procédure : lire .claude/skills/context-governance/SKILL.md" >&2
  exit 2
fi
exit 0
