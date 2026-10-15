# Historical corpus (Phase 15)

The first real corpus: nine snapshots across eight repositories — OTP
17.5 and OTP 18.0, SWI-Prolog 7.2.0, GNU Prolog 1.4.4, Elixir 1.0.5,
Phoenix 1.0.0, GCC/GNAT 4.2.0, SPARK 0.3 draft, and UCSD OS. Every
snapshot is a pinned commit with a recorded archive SHA-256 and
independent Git-tree evidence.

SWI-Prolog's 34 gitlinks are recorded here but *not* fetched — this is a
verified superproject corpus, not a dependency closure. The
`swipl-corpus/` directory finishes that job.

## What is inside

- `bin/normalize.pl` — Walks every file: Git blob SHA-1 check against
  the upstream tree, SHA-256 identity, language classification, partial
  structure extraction. Writes the ledgers.
- `bin/report.pl` — Builds the ingestion, verification, and handoff
  reports from the ledgers. No hardcoded counts.
- `bin/verify.pl` — Independently rehashes everything and runs the
  gates: `independent_file_bytes_and_git_blobs`,
  `license_evidence_integrity`, `training_partition`, `exact_totals`,
  `duplicates`, per-snapshot version/license gates,
  `phase14_preserved`.
- `bin/package.sh` — Reproducible tarball of this corpus plus the
  seed archive.
- `bin/replay.pl`, `bin/export-training.pl`, `bin/supplement-otp.pl`,
  `bin/audit-seed-archive.pl`, `bin/check-examples.sh` — Offline replay,
  guarded training export, OTP blob supplement, seed-archive audit,
  example checks.
- `tests/structure.t` — The structural extractor's test suite (12
  assertions).

## Outputs (generated, not committed)

`SOURCE_INVENTORY.jsonl`, `PROVENANCE_MANIFEST.jsonl`,
`LICENSE_AUDIT.jsonl`, `TRAINING_ELIGIBILITY.jsonl`,
`normalized/sha256/`, `normalized/STRUCTURE.jsonl`,
`reports/DUPLICATES.jsonl`, `reports/QUARANTINE.jsonl`,
`reports/TOTALS.json`, `INGESTION_REPORT.md`,
`VERIFICATION_REPORT.md`, `PHASE15_HANDOFF.md`.

## Run

```sh
cd historical-corpus && perl bin/normalize.pl && perl bin/report.pl && perl bin/verify.pl
```

The verifier expects `../seed-archive/` to be present.
