---
name: project-shoptrack-state
description: "ShopTrack is in controlled-beta stage, not production-ready; known remaining work tracked in repo docs"
metadata: 
  node_type: memory
  type: project
  originSessionId: dc80caf0-1f4e-4f46-9400-be4673bc3c4e
---

As of late July 2026, ShopTrack is considered ready for a **controlled beta**
(a few real users/shops) but explicitly **not yet production-final**. This
assessment lives in `RECAPITULATIF_TECHNIQUE.md` and
`PLAN_CORRECTIONS_ET_AMELIORATIONS.md` at the repo root (dated 27-28 July
2026) — see [[project-shoptrack-docs]].

**Why:** the author ran a self-audit and fixed a first round of critical bugs
(QR scanner camera lifecycle/errors, multi-phone product sync, cash-gap
display in reports, atomic stock updates, PIN no longer stored in plaintext,
signed release APK) but multi-device/multi-day real-world testing has not
been completed, and several items are explicitly still open:
- test the release APK on several real phone brands/OS versions simultaneously
- test concurrent sales of the same product from two phones
- test multiple consecutive offline days
- add Drift/Supabase integration tests
- add production crash reporting
- write a privacy policy / terms of use before any public release
- `mobile_scanner` version works now but Flutter flags a future Kotlin
  incompatibility — needs an upgrade pass later
- bump `versionCode` on every release; only build an AAB once Play Store
  publication is actually decided

**How to apply:** when asked to add features or "finish" the app, check
whether the request overlaps with this open list before assuming it's new
scope. Don't treat the current beta APK as production-grade. The Android
release keystore/passwords (`android/shoptrack-release.jks`,
`android/release-signing.pass`, `android/key.properties`) are local-only,
gitignored, and must never be committed — losing them blocks all future
signed updates, so flag any accidental attempt to remove them from
`.gitignore` or delete them.
