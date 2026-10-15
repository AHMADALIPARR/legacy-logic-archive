# Seed archive (Phase 14)

The seed scaffold the whole archive grows from. Content-addressed archival
scaffolding for JOVIAL, ALGOL, COBOL II, and Prolog — plus the pristine
originals that every later phase is checked against.

## What is inside

- `bin/` — Collectors and the verifier: permission-aware collection
  (`collect.sh`), content-addressed ingest (`ingest.sh`), Git archive
  handling (`git_archive.sh`), OTP epoch audit, NASA Prolog scan, and
  Phase 9/10/13 lists. These are expanded copies with license headers.
- `legacy-logic-archive/` — The 38 pristine originals, byte-identical to
  the supplied package (32,676 bytes). **Never modify these files.**
  The historical-corpus verifier hashes their exact bytes.

## Rules

- No fetched historical sources live here — only collector code and one
  local 19-byte test object (`parent(alice,bob).`).
- The collector fetches only HTTPS sources whose license classification
  has been explicitly approved, with a 25 MB per-file cap.
- `sources/candidates.tsv` is a research queue, not a download
  authorization.

## Run

```sh
cd seed-archive/legacy-logic-archive && sh bin/verify.sh
```
