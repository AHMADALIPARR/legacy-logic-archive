# Legacy Logic Archive — local seed

Content-addressed archival scaffold for JOVIAL, ALGOL, COBOL II, and Prolog.

## Ingest

`bin/ingest.sh ALGOL https://example.org/original-source ./downloaded-file`

The command copies bytes into `objects/sha256/<first-two-hex>/<sha256>` and appends a TSV record. No fetched sources are included in this seed package. Only ingest material after checking download permission and license terms. The `unreviewed` rights state must be resolved before redistribution or model training.

## Research starting points

- https://softwarepreservation.computerhistory.org/ALGOL/
- https://softwarepreservation.computerhistory.org/ALGOL/algol58impl.html
- https://softwarepreservation.computerhistory.org/ALGOL/applications.html
- https://github.com/SWI-Prolog/swipl-devel

## Next engineering gates

Add a manifest lock, atomic writes, URL canonicalization, license review, archive crawl policies, MIME checks, malware-safe quarantine, Git commit provenance, reproducible builds, and parser verification. This seed is not a finished crawler or a complete historical archive.

## Phase 2: permission-aware collector

`bin/collect.sh sources/approved.tsv` fetches only HTTPS sources whose license
classification has been explicitly approved. `sources/candidates.tsv` is a
research queue, not a download authorization. Use `bin/verify.sh` to rehash
all stored objects. The collector does not run code, follow arbitrary schemes,
or interpret backticks from remote content. It enforces a 25 MB per-file cap.

Metadata is appended as TSV: hash, language, URL, size, UTC time, rights, note.
For reproducible versioned source, prefer immutable commit-specific raw URLs;
branch URLs are not stable. Source discovery is not proof of redistribution or
AI-training rights. Human review is needed before approving additional files.

Network access was unavailable in the build environment. This release includes
collector code and verified local smoke tests, but no remote source download.

## Phase 6 — VHDL-87 and 1980s BASIC magazines
See `research/PHASE6_VHDL_BASIC.md` and `research/phase6_sources.tsv` for nine discovery records. Historical source bytes remain pending rights checks and retrieval. Do not treat later VHDL examples as authenticated 1980s originals.

Phase 10: 2007 Ada aerospace catalog in research/phase10_ada_aerospace.tsv. Historical source not yet fetched.

## Phase 11 — Mark I Perceptron
See research/PHASE11_ROSENBLATT.md and phase11_rosenblatt_sources.tsv. This phase adds evidence-indexed architecture metadata, not recovered original source code.
