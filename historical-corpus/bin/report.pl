#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use FindBin;
use POSIX qw(strftime);

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->utf8->canonical;

sub data {
    open my $f, '<', $_[0] or die $!;
    local $/;
    return $j->decode(<$f>);
}

my $s = data('reports/TOTALS.json');
my (%qh, %nh);
my ($enc, $normbad) = (0, 0);

open my $inventory, '<', 'SOURCE_INVENTORY.jsonl'
    or die $!;

while (<$inventory>) {
    my $record = $j->decode($_);

    $qh{$record->{sha256}} = 1
        if $record->{training_status}
            eq 'quarantined_pending_review';

    if ($record->{normalized}) {
        if ($record->{normalized}{sha256}) {
            $nh{$record->{normalized}{sha256}} = 1;
        }
        else {
            $enc++;
        }
    }
}

$s->{unique_quarantined_files} = scalar keys %qh;
$s->{unique_normalized_derivatives} = scalar keys %nh;
$s->{source_records_encoding_unresolved} = $enc;

open my $totals_file, '>', 'reports/TOTALS.json'
    or die $!;

print {$totals_file} $j->pretty->encode($s);
close $totals_file;

my @provenance;

open my $provenance_file, '<', 'PROVENANCE_MANIFEST.jsonl'
    or die $!;

push @provenance, $j->decode($_) while <$provenance_file>;

my $table =
    "| Snapshot | Commit | Files | Payload bytes |\n"
    . "|---|---|---:|---:|\n";

for my $record (@provenance) {
    $table .=
        "| $record->{id} | `$record->{commit}`"
        . " | $record->{files} | $record->{file_bytes} |\n";
}

my $totals =
    "| Measurement | Exact total |\n"
    . "|---|---:|\n";

for my $key (
    qw(
        repositories
        snapshots
        file_occurrences
        unique_files
        total_file_bytes
        unique_bytes
        duplicate_occurrences
        source_code_tokens
        unique_source_code_tokens
        quarantined_file_occurrences
        unique_quarantined_files
        training_eligible_file_occurrences
        unique_training_eligible_files
        normalized_source_records
        unique_normalized_derivatives
        source_records_encoding_unresolved
        git_blob_mismatches
        missing_git_blobs
        unfetched_submodules
    )
) {
    $totals .= "| $key | $s->{$key} |\n";
}

open my $r, '>', 'INGESTION_REPORT.md' or die $!;

print {$r} <<EOF;
# Phase 15 ingestion report

Authentic upstream source bytes were downloaded for eight distinct repositories at nine snapshots. Research/catalog entries are excluded from all corpus totals. Original Phase 14 material remains unchanged in ../seed-archive; its 38 regular files total 32,676 bytes and contain one local 19-byte test object, not historical ingestion.

$totals

EOF

print {$r} <<EOF;
Unique files mean unique SHA-256 payloads across regular files and symlink-target bytes, not unique paths. File occurrences count each snapshot path; duplicate occurrences are occurrences minus unique payloads. Archive/container bytes and Git history storage are excluded from unique source payload bytes. The original Phase 14 test is excluded. Token totals use the exact documented ASCII identifier/integer/symbol lexical metric, including comments and strings; they are not model-token counts. Unique source tokens count each source payload hash once. Some byte-identical files have different licensing contexts; unique eligible and quarantine sets may overlap.

$table

Every snapshot has compressed archive SHA-256, exact commit, requested tag/revision, upstream URL, UTC download start/end, commit date and independent Git-tree evidence in PROVENANCE_MANIFEST.jsonl. Commits are pinned; signatures were not verified. Publication/release dates must not be inferred from download timestamps or commit dates.

Two OTP tar exports omitted 757 tracked configuration/ignore files. Those original tarballs are preserved unchanged. The missing bytes were recovered from shallow Git fetches into supplemental/, and are separately inventoried against the same commit trees. Thus all non-submodule blobs are accounted for. The complete UCSD Git mirror has 14 reachable commits and passed fsck. OTP retains a shallow object store for two releases; other large histories were not mirrored to keep acquisition bounded. Full history preservation is therefore partial.

SWI-Prolog's 34 gitlinks/submodules are recorded but not fetched; this is a verified superproject corpus, not a complete dependency closure. Phoenix/Mix dependencies and platform/compiler libraries are declared references, not ingested third-party packages. No skipped dependency is counted as downloaded source.

Normalization stores strict UTF-8, LF-normalized content-addressed derivatives separately in normalized/sha256, and partial declaration/dependency extraction in normalized/STRUCTURE.jsonl. Encoding failures are explicit and originals are unchanged. Line-based extraction is not a complete grammar parser or resolved dependency graph. SOURCE_INVENTORY.jsonl links originals, normalized hashes, provenance, per-file license/training decisions and compilation status. Detailed license policy and observed release evidence are in reports/LICENSE_POLICY.md.

Quarantine is logical and enforced by bin/export-training.pl: reports/QUARANTINE.jsonl lists excluded contexts, and only explicit verified permissive file grants can enter a training export. No training or public redistribution was performed. Verified training eligibility here means passing the documented permissive-use policy, not an express AI-training clause or jurisdiction-independent legal authorization.
EOF

close $r;

open my $v, '>', 'VERIFICATION_REPORT.md' or die $!;

print {$v} <<'EOF';
# Phase 15 verification report

The executable machine results are reports/VERIFICATION_RESULTS.jsonl; evidence/verification.log and evidence/verification.exit retain the run output/status. bin/verify.pl independently rehashes every original payload, compares its Git blob SHA-1 with the commit-pinned upstream tree, reconstructs tree objects to bind them to commit tree hashes, reconciles manifest counts/bytes, independently recomputes normalized UTF-8/LF derivative hashes, checks duplicate groups and license evidence, verifies historical version bytes and checks original Phase 14 preservation. SHA-256 is the immutable corpus identifier; Git SHA-1 is an additional upstream object identity check.

Checks and their scope:

* Download integrity: all nine preserved compressed snapshots have recorded SHA-256 and size; gzip integrity was checked at ingestion. HTTPS upstream metadata and independent Git object checks establish provenance without claiming signed-release authentication.
* Manifest consistency: all snapshot paths and non-submodule Git blobs reconcile. OTP export omissions are repaired using separately preserved Git-derived bytes. Gitlinks stay explicit.
* Duplicate detection: repeated SHA-256 payloads are enumerated in reports/DUPLICATES.jsonl and independently reconciled with totals. This is exact byte duplication, not near-clone detection.
* Historical version: OTP_VERSION, SWI VERSION, Elixir VERSION, Phoenix mix.exs and GCC BASE-VER are checked from source bytes. GNU Prolog and SPARK are commit/tag pinned; UCSD is a later preservation commit with historical license/source lineage, not an authenticated original medium.
* License evidence: per-file signals and release notice hashes are checked. This is conservative evidence-backed classification with explicit unresolved cases; it is not a complete manual legal audit.
* Structural extractor: tests/structure.t passes 12 assertions covering six supported language subsets and literal dependencies. Full grammar/parser correctness is INCOMPLETE. Multiline declarations, C preprocessing, quoted Prolog functors, nested comment/string constructs and generated syntax are not exhaustively supported. Per-file structure_status explicitly says partial.
* Reproducible compilation and execution: two reviewed upstream GCC C regression examples, 20000112-1.c and 20000113-1.c, compiled and executed successfully. Each was built twice with the same recorded native compiler/platform/flags and produced an identical binary SHA-256. This verifies those examples on this environment, not a reproducible 2007 GCC compiler build or cross-machine reproducibility. Compiler version, build logs, hashes and evidence/example-results.tsv are retained.

Failed/incomplete gates:

* FAILED: SWI-Prolog 7.2.0 configure attempt exited 1: ../src/configure was missing. The Git snapshot requires generated files/submodule preparation and autoconf; evidence/swi-configure.log preserves the exact failure. No SWI executable verification is claimed.
* NOT RUN: complete OTP, Elixir, Phoenix, GNU Prolog, GNAT, SPARK and UCSD builds. Required Erlang/Elixir, Prolog, Ada bootstrap, historical UCSD toolchain and/or generated dependencies were unavailable. None of these is reported as a successful build. Full historical toolchains and dependency closure remain handoff work.
* INCOMPLETE: full native parser validation and dependency resolution across all languages; scanner/extractor results are partial.
* INCOMPLETE: SWI submodule ingestion, most full Git histories, signed release authentication, original UCSD media authentication and manual review of quarantined licensing contexts.
* RESOLVED TOOLING FAILURE: the initial independent verifier run used an incorrect tree-response assumption and mishandled Unicode filenames. Its failure output is preserved in evidence/verification-initial-failed.log. The corrected verifier reconstructs actual tree objects and handles UTF-8 paths; only the final run determines present integrity status.

No failed check is silently converted to a pass. Core byte ingestion can be complete while the broader parser/build program still has explicit gaps. Consult PHASE15_HANDOFF.md before treating the entire research mission as finished.
EOF

close $v;

open my $h, '>', 'PHASE15_HANDOFF.md' or die $!;

print {$h} <<'EOF';
# Phase 15 handoff

Delivered: populated, commit-pinned source corpus; unchanged upstream archives/originals; supplemental OTP Git blobs; one full UCSD history and a shallow two-release OTP object store; complete per-path inventory, provenance, license/eligibility ledgers; separate normalized text/structural derivatives; duplicate/quarantine indexes; independently executable integrity tests and recorded native example results.

Status: core source-byte ingestion is populated and independently verifiable. The entire Phase 15 mission is PARTIAL because full parser correctness, historical builds, dependency closure and manual licensing review are incomplete. Do not describe this as a fully compiled or universally training-cleared historical corpus.

Required deliverables are at this directory root:

* SOURCE_INVENTORY.jsonl
* PROVENANCE_MANIFEST.jsonl
* LICENSE_AUDIT.jsonl
* TRAINING_ELIGIBILITY.jsonl
* INGESTION_REPORT.md
* VERIFICATION_REPORT.md
* PHASE15_HANDOFF.md

Exact totals and definitions are in reports/TOTALS.json and INGESTION_REPORT.md. The eight repositories are OTP, SWI-Prolog, GNU Prolog, Elixir, Phoenix, GCC/GNAT, SPARK and UCSD OS; OTP has two releases.

Run from this directory:

```sh
perl bin/verify.pl
perl tests/structure.t
sh bin/check-examples.sh
```

The verifier expects ../seed-archive/legacy-logic-archive to be present. If only this package is available, recreate that directory from evidence/phase14-original.zip without modifying its bytes. Dependencies are core Perl modules and POSIX/native utilities documented in reports/PHASE14_AUDIT.md. Original source is never executed by the normalization pipeline. Example execution is confined to the two reviewed C programs with a timeout.

For repeatable derivatives, preserve the pinned ledgers and run `perl bin/normalize.pl`, then `perl bin/report.pl`; verify afterward. For acquisition replay, `perl bin/replay.pl /absolute/new-directory` verifies stored download hashes and extracts them into a new location; append --network to re-download exact commit URLs with expected hashes. Supplemental OTP files remain in this package and the Git object store. bin/supplement-otp.pl documents their Git extraction. Do not re-run discovery fetches against moving HEAD as if they reproduced the locked run. Export-only tar hashes can change if an upstream changes tar metadata; reject a changed archive and investigate rather than silently replacing its lock.

Licensing: consult reports/LICENSE_POLICY.md. Preserve all copyright/license/NOTICE files. UCSD historical Pascal and every unresolved file context are quarantined. To create a guarded training subset, `perl bin/export-training.pl /absolute/new-training-directory` checks the allowlist and hashes and carries original notices. This is an implementation of the stated permissive-use policy, not a waiver of legal obligations.

Priority continuation:

1. Fetch and individually inventory SWI's 34 pinned submodules/generated-file dependencies; rebuild the historical core and run real Prolog examples. Preserve each added repository's provenance and licenses.
2. Obtain native historical-compatible OTP, Elixir/Phoenix, GNAT/Ada and UCSD toolchains; use separate build trees, record compiler/dependency hashes, and run reviewed language examples. Do not alter original source to accommodate new compilers; patches belong in separate derivatives.
3. Replace partial line extraction with native parser-backed AST extraction and test complex syntax and dependency resolution. Retain original bytes and current heuristic labels until replaced.
4. Manually review component/file rights, runtime exceptions, Erlang Public License obligations and UCSD purpose restrictions before expanding the allowlist or publicly redistributing the full package.
5. Preserve more complete histories where feasible; add signed-tag verification and original-medium provenance where available. The 2023 UCSD commit and 2013 SPARK draft must retain their distinct historical meanings.
EOF

close $h;

print "Reports written from exact manifests\n";
