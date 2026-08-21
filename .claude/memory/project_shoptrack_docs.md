---
name: project-shoptrack-docs
description: "Where ShopTrack's own status docs, DB migrations, and required setup steps live"
metadata: 
  node_type: memory
  type: reference
  originSessionId: dc80caf0-1f4e-4f46-9400-be4673bc3c4e
---

In `/home/jack/Projets_SSD/shoptrack`:

- `README.md` — setup, mandatory Supabase migration order, Android signing
  setup, pre-production manual test checklist.
- `RECAPITULATIF_TECHNIQUE.md` — technical changelog / current state as of
  28 July 2026 (most reliable single doc for "what does this app currently
  do and why").
- `PLAN_CORRECTIONS_ET_AMELIORATIONS.md` — original bug audit + fix plan +
  backlog of short/medium/long-term feature ideas; still useful as a
  prioritized backlog even though most "priority critique" items are marked
  implemented at the top of the file.
- `supabase/migrations/` — SQL migrations that must be applied **in
  filename order** via `supabase db push` before installing a new build on
  phones (atomic stock RPC `apply_stock_movement`, unique barcode index,
  RLS policies). Currently two migrations:
  `202607270001_secure_sync.sql`, `202607280002_stock_sync_and_unique_barcodes.sql`.

See [[project-shoptrack-state]] for the interpretation of these docs'
current status.
