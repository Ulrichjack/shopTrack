#!/bin/bash
# Sauvegarde/restauration de la mémoire Claude du projet dans le repo (versionnée par git).
# La mémoire vit hors du repo (~/.claude/projects/<slug>/memory/) ; ce script la copie
# dans .claude/memory/ pour pouvoir la retrouver depuis git sur une autre machine.
#
# Usages :
#   sync-memory.sh save      # copie mémoire → repo (.claude/memory/)
#   sync-memory.sh restore   # copie repo → mémoire (nouvelle machine)
#   (mode hook PostToolUse)  # sans argument : save automatique si un fichier mémoire vient d'être écrit

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SLUG=$(echo "$PROJECT_DIR" | tr '/' '-')
MEM_DIR="$HOME/.claude/projects/$SLUG/memory"
BACKUP_DIR="$PROJECT_DIR/.claude/memory"

case "$1" in
  save)
    ;;
  restore)
    if [ ! -d "$BACKUP_DIR" ]; then
      echo "Aucune sauvegarde dans $BACKUP_DIR" >&2
      exit 1
    fi
    mkdir -p "$MEM_DIR"
    cp "$BACKUP_DIR"/*.md "$MEM_DIR"/ 2>/dev/null
    echo "Mémoire restaurée : $BACKUP_DIR → $MEM_DIR"
    exit 0
    ;;
  *)
    # Mode hook : ne réagir que si l'écriture concerne un fichier mémoire de CE projet
    input=$(cat)
    echo "$input" | grep -q "/projects/$SLUG/memory/" || exit 0
    ;;
esac

[ -d "$MEM_DIR" ] || exit 0
mkdir -p "$BACKUP_DIR"
cp "$MEM_DIR"/*.md "$BACKUP_DIR"/ 2>/dev/null
exit 0
