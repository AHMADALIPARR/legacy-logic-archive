#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new;

sub json {
    open my $f, '<', $_[0] or die $!;
    local $/;
    return $j->decode(<$f>);
}

my $t = json('reports/TOTALS.json');
my $c = json('reports/CUMULATIVE_TOTALS.json');
my $p = json('reports/PARSER_TOTALS.json');

open my $f, '>', 'INGESTION_REPORT.md';

print {$f} <<"TEXT";
# Phase 17 ingestion report

Phase 17 adds authentic OpenSSL 1.0.2c source to close the historical crypto dependency of OTP 18 and Elixir 1.0.5. This is an incremental archive: Phase15 and Phase16 remain required baselines. It does not replace their source or license evidence.

Upstream: https://github.com/openssl/openssl, tag OpenSSL_1_0_2c, commit 0ee5fcde06827b041023e5a596d58da98e53740c. The preserved 5,314,156-byte archive was downloaded 2026-10-15T05:59:37Z–05:59:40Z. SHA-256: 86a09a3084c61a9329063ee50d669741b8b758dc63563de2125b4d1b183b820d. This is a commit snapshot, not full Git history; release signatures were not verified. HTTPS upstream evidence and reconstructed Git trees establish consistency with the retrieved upstream commit, not independent author-signature authentication.

| Count | Phase17 addition | Cumulative Phase15–17 |
|---|---:|---:|
| Repositories | $t->{repositories} | $c->{repositories} |
| Snapshots | $t->{snapshots} | $c->{snapshots} |
| File occurrences | $t->{file_occurrences} | $c->{file_occurrences} |
| Unique source-tree file contents | $t->{unique_files} | $c->{unique_files} |
| Unique bytes | $t->{unique_bytes} | $c->{unique_bytes} |
| Total occurrence bytes | $t->{total_file_bytes} | $c->{total_file_bytes} |
| Duplicate occurrences | $t->{duplicate_occurrences} | $c->{duplicate_occurrences} |
| Source lexical tokens | $t->{source_code_tokens} | $c->{source_code_tokens} |
| Unique-content source lexical tokens | $t->{unique_source_code_tokens} | $c->{unique_source_code_tokens} |
| Quarantined file contexts | $t->{quarantined_file_occurrences} | $c->{quarantined_file_occurrences} |
| Unique quarantined contents | $t->{unique_quarantined_files} | $c->{unique_quarantined_files} |
| Conditional training-eligible contexts | 0 | $c->{conditionally_training_eligible_file_occurrences} |
| Unique conditional training-eligible contents | 0 | $c->{unique_conditionally_training_eligible_files} |

These counts cover downloaded source-tree files, including documentation and ancillary files; discovery records, build products, runtimes, and tooling are excluded. Tokens mean ASCII identifiers, integers, or each non-whitespace symbol in extension-identified source, including comments/strings. They are not model tokens or claims of complete language detection. Content shared across contexts can appear in both the eligible and quarantined sets; unique partitions need not sum to the overall unique count.

All $t->{file_occurrences} new file bytes match the upstream Git blob tree. The full tree is reconstructed against the commit tree hash; the preserved archive and a fresh offline extraction are independently checked. There are $t->{normalized_source_records} normalized source records and $t->{encoding_unresolved} source records with unresolved UTF-8 encoding. Original bytes remain intact. New .pl assembly generators are identified as Perl; util/indent.pro is configuration.

Historical licensing: OpenSSL 1.0.2c retains OpenSSL and original SSLeay obligations. Explicit file-specific Apache/MIT evidence is retained separately. All new files remain quarantined pending component review: archival possession, redistribution, and training are distinct decisions. No new training eligibility is granted. The cumulative conditional eligibility is inherited policy metadata, not a legal clearance or training run. OTP17's Erlang Public License 1.1 and OTP18's Apache 2.0 transition remains unchanged; bundled-component exceptions remain in the baseline ledgers. UCSD restrictions remain in force.

OpenSSL was built serially without assembler, with position-independent C objects, in a separate build copy. OTP18 now loads that libcrypto and passes a SHA-256 known-answer vector. Elixir1.0.5 builds on this OTP18 and runs Base64, Task, and crypto checks; its upstream BaseTest passes 94 tests. These are local builds, not cross-host bit-reproducibility claims. No public deployment, publication, redistribution authorization, or training operation is implied.
TEXT

close $f;

open $f, '>', 'VERIFICATION_REPORT.md';

print {$f} <<"TEXT";
# Phase 17 verification report

Native overlay covers $p->{total_files} inherited source records: $p->{parsed_files} syntax-reader/syntax-only passes and $p->{remaining_failures} unresolved failures. Of 1,610 baseline failures, 613 are repaired: Prolog 568, Erlang 40, Elixir 5, Ada 0. No previously passing Prolog file regressed. This is parsing, not semantic correctness or whole-program compilation.

| Language | Remaining failures | Verification scope |
|---|---:|---|
| Prolog | 28 | SWI9 read_term, source-derived literal operator contexts; one OS process per file |
| Erlang | 874 | Historical OTP18 epp_dodger for prior failures; preserves macro syntax, no preprocessing |
| Elixir | 37 | Historical Elixir1.0.5 Code.string_to_quoted for prior failures; no evaluation |
| Ada | 58 | GNAT14 syntax-only retry with bracket wide-character setting; historical compiler pending |

Every baseline failure has one classification with immutable source hash and evidence linkage. Provisional categories are explicitly qualified: macro presence alone does not prove a preprocessing cause. Thirty-six Phoenix failures contain EEx template delimiters and require rendering. Four inherited Prolog inputs are indent, qmake, or Makefile configuration; metadata corrections do not turn failed parses into passes. One Ada file contains historical wide-character notation; the compatibility retry still fails. Other errors remain unresolved. Original Phase16 parser evidence remains unchanged.

The final Prolog driver runs each file in a fresh process, preventing operator/autoload state leaking between files. Registries read literal module/operator declarations from pinned source without consulting it. Tests exercise literal custom operators, quoted DCG names, invalid syntax, a directive that would throw if executed, and cross-file isolation. Native ASTs/terms, diagnostics, and artifact hashes are retained. Exploratory shared-process runs are retained as evidence but excluded from final totals.

Actual failures preserved:

- OpenSSL assembly/shared build failed relocation; no-assembler replacement succeeded.
- A parallel no-assembler build failed to link; serial make succeeded.
- Unmodified OpenSSL make test fails exit 2 at the current certificate-verification date because archived CMS certificates expired. The original failure and certificate dates remain recorded.
- A separate build-copy-only patch adds -attime 1434067200 to CMS verification. The full suite then passes. Certificate verification is retained; no clock change, no noverify flag, no source-original edit. The first incomplete signed-receipt patch failure is also preserved.
- All 58 Ada retries still fail. Full Phoenix dependency closure, OTP17 compilation, historical GNAT/SPARK compilation, and UCSD execution remain unverified.
- Two Phase16 outputs named JSONL were pretty JSON text sequences. Their original bytes are preserved; compact strict-JSONL derivatives are under normalized/inherited/. New deliverable ledgers are checked per physical line.

See reports/SOURCE_VERIFICATION_RESULTS.jsonl for archive SHA-256, full Git tree/blob reconciliation, normalization, duplicates, licenses, versions and totals. See reports/VERIFICATION_RESULTS.jsonl for final independent gates; BUILD_RESULTS.jsonl records observed stage exits, including the unmodified suite failure. Driver exit success is never substituted for per-file parser success.

Offline archive replay is verified. Build recipes record compatibility changes and exact tool/runtime hashes. A second independent build of the Phase17 runtimes and cross-host byte-for-byte compilation reproducibility have not been demonstrated. Runtime executables use local build/install paths and require rebuilding after relocation; source archives and provenance are portable.
TEXT

close $f;

open $f, '>', 'PHASE17_HANDOFF.md';

print {$f} <<'TEXT';
# Phase17 handoff

Delivered: one verified OpenSSL1.0.2c source snapshot; crypto-enabled historical OTP18; compiled historical Elixir1.0.5; 613 repaired baseline parser failures; full classification of all 1,610 prior failures. Remaining parser failures: 997. This is a completed bounded ingestion/build increment, not completion of all historical compiler and license-review work.

Keep phase15/, phase16/, and phase17/ as siblings. Baseline archive checksums and ledger locks are in evidence/. This delta intentionally excludes large build trees except Elixir1.0.5, whose generated BEAM libraries are used by historical parser rechecks. All Phase17 upstream archives, untouched originals, native result derivatives, installed runtime bytes, scripts, patches, and failure logs are retained.

Required ledgers are SOURCE_INVENTORY.jsonl, PROVENANCE_MANIFEST.jsonl, LICENSE_AUDIT.jsonl, TRAINING_ELIGIBILITY.jsonl. They describe new source only. Cumulative metrics are reports/CUMULATIVE_TOTALS.json. PARSER_RESULTS.jsonl overlays all 13,902 inherited parser inputs; PARSER_FAILURE_CLASSIFICATION.jsonl covers each of the 1,610 inherited failures exactly once. Follow evidence_file and id to the full native records.

Reproduction, from phase17/ with the Phase16 toolchain available:

1. `perl bin/replay.pl /absolute/new-empty-directory` verifies and extracts the preserved pinned archive offline. Add `--network` to fetch the exact URL again when network access is allowed. Re-downloaded upstream-generated tar bytes could change; the pinned archive hash gate will reject changes.
2. `perl bin/normalize.pl` then `perl bin/apply-source-policy.pl` regenerates derivatives and enforces the historical crypto hold. Normalization alone is not the final policy output.
3. `perl bin/verify-source.pl` independently verifies source/normalized bytes and Git-tree consistency.
4. For a clean rebuild, move existing builds and runtime aside; run `sh bin/build-openssl.sh`, then `sh bin/build-historical-stack.sh`. The crypto recipe preserves the unmodified current-time suite failure and gates the separately patched historical-time suite. Expect legacy host/compiler assumptions and the Phase16 toolchain dependency; builds are local-path dependent.
5. `sh bin/recheck-parsers.sh` runs the native parsers with source-derived context. It rebuilds pinned operator registries, uses fresh Prolog processes, retains AST/diagnostic artifacts, and writes the overlay. It does not execute archived directives.
6. `perl bin/cumulative-totals.pl`, `perl bin/record-builds.pl`, `sh bin/runtime-lock.sh`, `perl bin/report.pl`, and `perl bin/verify-phase17.pl` refresh reports/checks. Stage .exit markers are captured by the original execution harness; preserve or refresh them only from actual command exits. The final verifier expects the external replay directory used above at /workspace/phase17-replay-check.

Next priorities: render and parse Phoenix EEx templates with a pinned dependency closure; resolve the 874 Erlang errors with explicit preprocessor/compiler context and negative-fixture expectations; investigate the remaining Prolog operators/dialects and Ada syntax with historical compilers; component-by-component OpenSSL rights review; repeat builds in a clean independent environment before asserting bit reproducibility. Preserve noncommercial UCSD and historical OTP licensing distinctions throughout.
TEXT

close $f;
