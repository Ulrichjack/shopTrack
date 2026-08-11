---
name: context-governance
description: "OBLIGATOIRE AVANT de modifier: CLAUDE.md, AGENTS.md, AGENT.md, .claude/skills/*, .claude/hooks/*, docs/, README.md, RECAPITULATIF_TECHNIQUE.md, PLAN_CORRECTIONS_ET_AMELIORATIONS.md, ou créer un nouveau skill projet. Déclencheurs: « ajouter une règle », « documenter », « où mettre », « nouveau skill », modification de CLAUDE.md ou de la doc racine. NE PAS utiliser pour: écrire du code Dart ou du contenu d'écran."
---

# Gouvernance du contexte — ShopTrack

## PRIMARY RESPONSIBILITY

Protéger l'architecture de contexte optimisée : décider OÙ va chaque information
documentaire, faire respecter le budget de CLAUDE.md et le format des skills projet.

## USE THIS SKILL WHEN

- On s'apprête à modifier CLAUDE.md, AGENTS.md, AGENT.md, un skill projet, un hook,
  ou un des docs de référence à la racine (`RECAPITULATIF_TECHNIQUE.md`,
  `PLAN_CORRECTIONS_ET_AMELIORATIONS.md`, `README.md`, `docs/`).
- On hésite sur l'emplacement d'une nouvelle règle, doc ou information.
- On crée un nouveau skill projet (template obligatoire ci-dessous).

## DO NOT USE THIS SKILL WHEN

- On écrit du code Dart, des migrations SQL ou du contenu d'écran (→ CLAUDE.md suffit).

## TRIGGERS

`CLAUDE.md`, `AGENTS.md`, `skill`, `documentation projet`, `règle`, `convention`,
`où mettre`, `gouvernance`, `docs/`, `architecture des modules`.

## OWNED DIRECTORIES

- `CLAUDE.md`, `AGENTS.md`, `AGENT.md`
- `.claude/skills/`, `.claude/hooks/`, `.claude/settings.json`, `.claude/memory/`
- `docs/` (architecture et plans des modules métier custom)
- `README.md`, `RECAPITULATIF_TECHNIQUE.md`, `PLAN_CORRECTIONS_ET_AMELIORATIONS.md`

## REQUIRED DEPENDENCIES

- Hook `.claude/hooks/check-context-budget.sh` (déclaré dans `.claude/settings.json`) —
  applique le budget de CLAUDE.md automatiquement.
- Hook `.claude/hooks/sync-memory.sh` — sauvegarde la mémoire projet dans
  `.claude/memory/` (versionnée git) ; `restore` sur une nouvelle machine.

## RELATED DOCUMENTATION

- Mécanisme d'origine : `trafric-website/.claude/skills/context-governance/SKILL.md`,
  répliqué dans `shoptrack` le 2026-08-08.

---

## Budget

| Fichier | Budget | Application |
|---------|--------|-------------|
| `CLAUDE.md` | **120 lignes max** | Hook automatique — bloque tout dépassement |
| `MEMORY.md` (mémoire) | index d'une ligne par mémoire | Détail dans des fichiers thématiques |
| Un skill | ~120 lignes | Au-delà, scinder ou renvoyer vers `docs/` |

## Règles de placement — où va quoi

| Contenu | Emplacement |
|---------|-------------|
| Règle nécessaire à CHAQUE session (stack, secrets, ordre sync, commandes) | `CLAUDE.md` — compact |
| Workflow déclenché par un TYPE de tâche | Skill dans `.claude/skills/<nom>/` |
| État technique / audit / backlog déjà consolidés | `RECAPITULATIF_TECHNIQUE.md`, `PLAN_CORRECTIONS_ET_AMELIORATIONS.md` |
| Architecture ou plan d'un module métier custom (cycles, multi-point...) | `docs/ARCHITECTURE_MODULES.md`, `docs/PLAN_<module>.md` |
| Point d'entrée agents tiers (renvois courts) | `AGENTS.md` / `AGENT.md` |
| Fait de session non dérivable du repo (décision client, deadline) | Mémoire projet (`~/.claude/projects/<slug>/memory/`) — jamais CLAUDE.md |

## Procédure OBLIGATOIRE avant de modifier CLAUDE.md

1. **Skill d'abord** : règle liée à un type de tâche ? → créer/enrichir le skill ;
   CLAUDE.md reçoit au plus 1 ligne dans « Workflows → Skills ».
2. **Référence ensuite** : donnée consultable et déjà stable ? → `docs/` ou un des
   docs de référence existants.
3. **Lien enfin** : la ressource existe ? → pointer, ne pas dupliquer.
4. **CLAUDE.md en dernier recours** : seulement si nécessaire à chaque session,
   en 1-3 lignes, en condensant l'existant si le budget approche.

Toute modification de CLAUDE.md doit le laisser plus petit ou égal, sauf justification explicite.

## Template OBLIGATOIRE pour tout skill projet

Frontmatter : `name` + `description` au format machine :
`"OBLIGATOIRE pour: <périmètre>. Déclencheurs: <mots-clés>. NE PAS utiliser pour: <exclusions>."`

Sections, dans cet ordre, avant le contenu : `PRIMARY RESPONSIBILITY`, `USE THIS SKILL WHEN`,
`DO NOT USE THIS SKILL WHEN`, `TRIGGERS`, `OWNED DIRECTORIES`, `REQUIRED DEPENDENCIES`,
`OPTIONAL DEPENDENCIES`, `RELATED DOCUMENTATION`.

## Checklist avant commit documentaire

- [ ] `wc -l CLAUDE.md` ≤ 120 ; skills ≤ ~120 lignes.
- [ ] Une information = un propriétaire ; les autres fichiers pointent.
- [ ] Aucun secret (clé Supabase `service_role`, mots de passe keystore) dans un fichier
      versionné — vérifier en particulier `lib/supabase_config.dart` (déjà suivi par
      Git, cf. règle CRITIQUE de `CLAUDE.md`).
- [ ] Nouveaux skills conformes au template.

## Anti-patterns (interdits)

- Coller dans CLAUDE.md le détail d'une feature livrée (→ `RECAPITULATIF_TECHNIQUE.md`
  ou un commit).
- Recopier une table/un flow déjà documenté (→ lien).
- Documenter deux fois « pour être sûr » (→ une source, des pointeurs).
- Stocker un état temporaire (avancement d'une conversation avec un client) dans
  CLAUDE.md (→ mémoire projet).
