# legacy-logic-archive

I built this to answer one question honestly: can you reconstruct a historical logic-programming corpus — Prolog, Erlang, Elixir, Ada, Pascal, C — from upstream sources, and prove every byte came from where it claims to?

No scraped blobs. No "trust me" manifests. Every file gets a SHA-256 identity, a Git blob SHA-1 checked against the commit-pinned upstream tree, a provenance record, a per-file license verdict, and a place in either the training-eligible set or quarantine. If any check fails, the pipeline exits 1. That is the whole system.

## Demo: the system in this checkout

This repo is code plus provenance logic — the corpus bytes themselves are fetched, not committed. But the verification machinery runs right now, on a fresh checkout, with no data:

```sh
# Every script parses. No exceptions.
$ for f in phase15/bin/*.pl phase16/bin/*.pl phase17/bin/*.pl; do perl -c $f; done
phase15/bin/audit-phase14.pl syntax OK
phase15/bin/normalize.pl syntax OK
# ... every Perl file, every phase

$ for f in phase15/bin/*.sh phase16/bin/*.sh phase17/bin/*.sh; do sh -n $f; done
# ... every shell script, every phase

# The structural extractor's test suite
$ perl phase15/tests/structure.t
1..12
ok 12 - C literal dependency extraction

# The Erlang native parser compiles
$ erlc -o /tmp phase16/native/parse_erlang.erl
$ erlc -o /tmp phase17/native/recheck_erlang18.erl
```

A full run — fetching, normalizing, reporting, verifying — needs the populated `evidence/`, `originals/`, and `downloads/` directories plus the historical toolchains. The run order, per phase:

```sh
cd phase15 && perl bin/normalize.pl && perl bin/report.pl && perl bin/verify.pl
cd phase16 && perl bin/normalize.pl && perl bin/report.pl && perl bin/verify.pl
cd phase17 && sh bin/recheck-parsers.sh && perl bin/report.pl && perl bin/verify-phase17.pl
```

## The corpus

```mermaid
flowchart TD
    P14["Phase 14 — Seed scaffold<br/>38 files, 32,676 bytes<br/>One local 19-byte test object<br/>No fetched sources"]
    P15["Phase 15 — Nine snapshots, eight repos<br/>OTP 17.5 and OTP 18.0<br/>SWI-Prolog 7.2.0, GNU Prolog 1.4.4<br/>Elixir 1.0.5, Phoenix 1.0.0<br/>GCC/GNAT 4.2.0, SPARK 0.3 draft<br/>UCSD OS"]
    P16["Phase 16 — SWI submodule corpus<br/>SWI-Prolog 7.2.0 superproject<br/>34 first-level gitlinks<br/>Parent-pinned commits<br/>Native parsers, locked toolchain"]
    P17["Phase 17 — Recheck plus crypto<br/>Native recheck of the 9 snapshots<br/>Prolog, Erlang 18, Elixir 1.0.5, Ada<br/>OpenSSL 1.0.2c collector"]
    P14 --> P15 --> P16 --> P17
```

**Phase 14** is the seed: a content-addressed archival scaffold for JOVIAL, ALGOL, COBOL II, and Prolog. It holds collector code and one local test object (`parent(alice,bob).`, 19 bytes) — no fetched historical sources. Everything later is checked against these pristine bytes, which are never modified.

**Phase 15** is the first real corpus: nine snapshots across eight repositories (OTP contributes two releases). Every snapshot is a pinned commit with a recorded archive SHA-256, an independent Git-tree evidence file, and per-path inventory. SWI-Prolog's 34 gitlinks are recorded but *not* fetched here — Phase 15 is a verified superproject corpus, not a dependency closure.

**Phase 16** finishes that job for SWI: it locks all 34 first-level gitlinks at the commits pinned by the parent superproject (parent `6442d29038b0e1ed413e2f1dfe8086b812777e7d`), fetches them, assembles SWI-Prolog 7.2.0 from the superproject plus submodules, and runs native parsers (SWI `read_term`, Erlang `epp_dodger`, Elixir `Code.string_to_quoted`, GNAT syntax-only) over the corpus. The modern toolchain is locked too: every build tool must match the signed Debian package-index SHA-256. Nested gitlinks below the 34 are still not fetched — this is a verified first-level corpus, not a complete dependency closure.

**Phase 17** rechecks the nine-snapshot corpus with native parsers and adds the OpenSSL 1.0.2c collector. The recheck classifies every Phase 16 parser outcome against a fresh native run, so a failure is evidence, not an error to paper over.

## How a run works

```mermaid
flowchart LR
    F["Fetch<br/>Pinned commits<br/>SHA-256 archives<br/>Provenance JSON"]
    N["Normalize<br/>SHA-256 plus Git blob SHA-1<br/>Inventory, provenance<br/>License audit, eligibility<br/>Structure, duplicates<br/>Quarantine"]
    R["Report<br/>Ingestion plus verification<br/>reports computed<br/>from the ledgers"]
    V["Verify<br/>Independent rehash<br/>Gate checks<br/>Results JSONL"]
    P["Package, replay, export<br/>Reproducible tar<br/>Offline replay<br/>Guarded training export"]
    F --> N --> R --> V --> P
```

**Fetch** downloads each snapshot at its pinned commit, records the archive SHA-256, and writes a provenance record (commit, tag, URL, UTC timestamps, tree evidence). **Normalize** walks every file, verifies its Git blob SHA-1 against the upstream tree, hashes it, classifies its language, extracts partial structure, and writes the ledgers: `SOURCE_INVENTORY.jsonl`, `PROVENANCE_MANIFEST.jsonl`, `LICENSE_AUDIT.jsonl`, `TRAINING_ELIGIBILITY.jsonl`, plus `reports/DUPLICATES.jsonl` and `reports/QUARANTINE.jsonl`. Normalized derivatives go to `normalized/sha256/` (strict UTF-8, LF line endings, no semantic rewriting). **Report** builds the ingestion, verification, and handoff reports from the ledgers — no hardcoded counts. **Verify** independently rehashes everything and runs the gate checks. **Package / replay / export** produce a reproducible tarball, replay a run into a fresh directory from stored hashes, and export a guarded training subset.

The verifiers are independent: they recompute hashes from the original bytes rather than trusting the normalizer's output. The gate names tell the story:

- Phase 15: `independent_file_bytes_and_git_blobs`, `license_evidence_integrity`, `training_partition`, `exact_totals`, `duplicates`, per-snapshot version and license gates, `phase14_preserved`
- Phase 16: the same core gates, plus `exact_pinned_swi_dependency_closure`, `phase15_manifests_preserved`, `native_toolchain_package_hashes`, `native_parser_source_and_artifact_links`, `historical_swi_executable_examples`, `native_parser_adversarial_fixtures`
- Phase 17: `strict_jsonl_deliverables`, `baseline_failure_classification`, `native_source_and_artifact_hashes`, `parser_aggregate`, `offline_source_replay`, `baseline_ledgers_preserved`, `runtime_hashes`, `unmodified_openssl_failure_visible`

## How a file gets cleared — or quarantined

```mermaid
flowchart TD
    A["File bytes in originals/"]
    B{"Git blob SHA-1<br/>matches upstream tree?"}
    C["FAILED: pipeline exits 1"]
    D["SHA-256 inventory<br/>License signal scan"]
    E{"Exactly one permissive<br/>signal? Apache-2.0 or MIT"}
    F["Quarantined<br/>reports/QUARANTINE.jsonl<br/>Excluded from export"]
    G["Eligible under the<br/>permissive-file-grant policy<br/>Notices preserved"]
    A --> B
    B -->|No| C
    B -->|Yes| D --> E
    E -->|No| F
    E -->|Yes| G
```

A root license is never enough. Eligibility requires a verified blob, exactly one file-level permissive signal, a source language, and a clean path — no `vendor/`, `third_party/`, `test/`, or `fixtures/` contexts, no UCSD OS (restricted purpose), no unresolved `Perl_or_Prolog` ambiguity. Everything else is quarantined, and quarantine is enforced by `export-training.pl`: only allowlisted files can enter a training export.

Manual review can override in either direction. In Phase 16, two files were reclassified by review: their full notices carry an additional Groupe Bull name-use clause, so they are not the exact MIT template. Overrides live in `evidence/LICENSE_REVIEW_OVERRIDES.jsonl`, in the open, not in a silent edit.

Eligibility is a policy decision about permissive use — not an express AI-training clause and not a jurisdiction-independent legal authorization. Nothing here is publicly redistributed on the strength of this pipeline alone.

## Layout

```
phase14/   Seed scaffold + 38 pristine originals (never modified)
  bin/                       Collectors and verifier (expanded copies)
  legacy-logic-archive/      Pristine originals, byte-identical
phase15/   Nine snapshots, eight repos
  bin/                       Normalize, report, verify, package, replay,
                             audit, supplement, export, check-examples
  tests/                     structure.t
phase16/   SWI submodule corpus + native parsers
  bin/                       Lock, fetch, assemble, normalize, attach-native,
                             verify, package, replay, builders, toolchain
  bin/native/                Toolchain wrappers (erl, erlc, gnatmake)
  native/                    parse_prolog.pl, parse_erlang.erl, parse_elixir.exs
  tests/                     Fixtures, adversarial cases, native-fixtures.t
phase17/   Native recheck + OpenSSL
  bin/                       fetch-corpus.pl, fetch.pl (OpenSSL), normalize,
                             recheckers, classifiers, verifiers, package,
                             builders, replay, report
  native/                    Prolog registry/parser, Erlang/Elixir rechecks
  tests/                     Prolog fixtures and fixture generator
  patches/                   openssl-cms-historical-time.patch
```

Three files in `phase16/bin/` are assistant-reconstructed, not user-supplied originals, and say so in-file and in their commit: `normalize.pl`, `report.pl`, `structure.pm`. `phase17/bin/fetch-corpus.pl` is the nine-target corpus fetcher; `phase17/bin/fetch.pl` is the separate single-target OpenSSL 1.0.2c collector. Replace any reconstruction with the original if it surfaces.

## Status: what is verified, what is partial

Verified in this checkout: every Perl file passes `perl -c`, every shell script passes `sh -n`, the Erlang parser compiles, `structure.t` runs 12/12, and the three reconstructed Phase 16 files were tested on synthetic fixture trees (hash/blob/totals recheck pass; missing-blob and mismatch fixtures exit 1). The Phase 14 pristine archive is byte-identical to its supplied zip, and its verifier passes.

Not verified here: full pipeline execution. The historical builds, the corpus downloads, and the native parser runs need the populated data directories and historical toolchains, which are not in this checkout. The per-phase handoff reports say the same in their own words — core byte ingestion is independently verifiable; parser correctness, full historical builds, dependency closure, and manual licensing review remain open. I do not describe this as a fully compiled or universally training-cleared corpus.

## License

GNU GPL v3. See `LICENSE`.
