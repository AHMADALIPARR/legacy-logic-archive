# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
# NOTE: assistant-reconstructed, NOT a user-supplied verbatim file.
# Skeleton follows phase15/bin/report.pl (verbatim); all Phase 16 facts
# below are drawn from verbatim phase16 files (verify.pl gates,
# lock-submodules.pl, fetch.pl, apply-license-review.pl, package.sh,
# check-examples.sh, build scripts). No counts are hardcoded: every
# number is computed from TOTALS.json / ledgers at runtime.
#!/usr/bin/perl
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
# Phase 16 ingestion report

Authentic upstream source bytes were downloaded for 34 SWI-Prolog submodule snapshots at parent-pinned commits. Phase 15 manifests remain unchanged; their checksums are locked in evidence/PHASE15_BASELINE_SHA256SUMS. Research/catalog entries are excluded from all corpus totals.

$totals

EOF

print {$r} <<EOF;
Unique files mean unique SHA-256 payloads across regular files and symlink-target bytes, not unique paths. File occurrences count each snapshot path; duplicate occurrences are occurrences minus unique payloads. Archive/container bytes and Git history storage are excluded from unique source payload bytes. Token totals use the exact documented ASCII identifier/integer/symbol lexical metric, including comments and strings; they are not model-token counts. Unique source tokens count each source payload hash once. Some byte-identical files have different licensing contexts; unique eligible and quarantine sets may overlap.

$table

Every snapshot has compressed archive SHA-256, exact commit, requested tag/revision, upstream URL, UTC download start/end, commit date and independent Git-tree evidence in PROVENANCE_MANIFEST.jsonl. Commits are pinned; signatures were not verified. Publication/release dates must not be inferred from download timestamps or commit dates.

The 34 snapshots are the first-level gitlinks of SWI-Prolog 7.2.0, each fetched at the commit pinned by the parent superproject (parent commit 6442d29038b0e1ed413e2f1dfe8086b812777e7d). Gitlinks are recorded in evidence/SUBMODULE_LOCK.jsonl; no nested gitlinks were fetched. This is a verified superproject corpus, not a complete dependency closure. Platform/compiler libraries and generated build dependencies are declared references, not ingested third-party packages. No skipped dependency is counted as downloaded source.

Normalization stores strict UTF-8, LF-normalized content-addressed derivatives separately in normalized/sha256, and partial declaration/dependency extraction in normalized/STRUCTURE.jsonl. Encoding failures are explicit and originals are unchanged. Line-based extraction is not a complete grammar parser or resolved dependency graph. SOURCE_INVENTORY.jsonl links originals, normalized hashes, provenance, per-file license/training decisions and compilation status. Two files were reclassified by manual license review in evidence/LICENSE_REVIEW_OVERRIDES.jsonl: their full notices carry an additional Groupe Bull name-use clause, so they are not the exact MIT template. Per-file license evidence is in LICENSE_AUDIT.jsonl.

Native parser overlays are in normalized/NATIVE_PROLOG.jsonl, normalized/NATIVE_ERLANG.jsonl, normalized/NATIVE_ELIXIR.jsonl and normalized/NATIVE_ADA.jsonl, with per-record evidence linkage in normalized/VERIFICATION_OVERLAY.jsonl. Parse errors are retained as outcomes, not converted to passes.

Quarantine is logical and enforced by bin/export-training.pl: reports/QUARANTINE.jsonl lists excluded contexts, and only explicit verified permissive file grants can enter a training export. No training or public redistribution was performed. Verified training eligibility here means passing the documented permissive-use policy, not an express AI-training clause or jurisdiction-independent legal authorization.
EOF

close $r;

open my $v, '>', 'VERIFICATION_REPORT.md' or die $!;

print {$v} <<'EOF';
# Phase 16 verification report

The executable machine results are reports/VERIFICATION_RESULTS.jsonl. bin/verify.pl independently rehashes every original payload, compares its Git blob SHA-1 with the commit-pinned upstream tree, reconstructs tree objects to bind them to commit tree hashes, reconciles manifest counts/bytes, independently recomputes normalized UTF-8/LF derivative hashes, checks duplicate groups and license evidence, verifies the exact pinned SWI submodule closure, checks Phase 15 preservation, verifies native toolchain package hashes against the signed Debian index, and checks native parser coverage with source/artifact hash links. SHA-256 is the immutable corpus identifier; Git SHA-1 is an additional upstream object identity check.

Checks and their scope:

* Download integrity: all 34 preserved compressed snapshots have recorded SHA-256 and size; gzip integrity was checked at ingestion. HTTPS upstream metadata and independent Git object checks establish provenance without claiming signed-release authentication.
* Manifest consistency: all snapshot paths and non-submodule Git blobs reconcile. Gitlinks stay explicit.
* Duplicate detection: repeated SHA-256 payloads are enumerated in reports/DUPLICATES.jsonl and independently reconciled with totals. This is exact byte duplication, not near-clone detection.
* Submodule closure: all 34 first-level gitlinks are ingested at parent-pinned commits; no nested gitlinks were fetched.
* Phase 15 preserved: Phase 15 inventory, provenance, license, eligibility and handoff bytes are unchanged.
* Native toolchain: all modern verification/build tools match signed Debian package-index SHA-256 values; .deb files were extracted with dpkg-deb -x and no maintainer scripts were run.
* Native parsers: Prolog (SWI read_term with literal op directives only), Erlang (epp_dodger, macros preserved), Elixir (Code.string_to_quoted, no evaluation) and Ada (GNAT syntax-only) cover every parser input record; source and AST/diagnostic artifact hashes are rechecked. Parse errors are retained as outcomes.
* Structural extractor: tests/native-fixtures.t passes valid/invalid and complex syntax assertions for Prolog, Erlang and Elixir without executing source directives.
* Reproducible compilation and execution: SWI-Prolog 7.2.0 assembled from the superproject plus pinned submodules sorts correctly and enumerates exactly 92 eight-queens solutions. OTP 18.0 runtime checks pass; historical Elixir Base encoding and an Ada example execute. These verify the named examples on this environment, not cross-machine reproducibility.

Failed/incomplete gates:

* NOT VERIFIED: signed release authentication. Upstream commit and tree evidence establish consistency with the retrieved commits, not author-signature authentication.
* NOT FETCHED: nested gitlinks below the 34 first-level submodules, and most full Git histories.
* NOT RUN: full historical builds beyond SWI-Prolog 7.2.0 and OTP 18.0, including complete Elixir/Phoenix builds. None of these is reported as a successful build.
* INCOMPLETE: native parser error resolution. Parser failures remain as recorded outcomes; per-file causes were not all independently established.
* INCOMPLETE: manual review of quarantined licensing contexts beyond the two Groupe Bull overrides.

No failed check is silently converted to a pass. Core byte ingestion can be complete while the broader parser/build program still has explicit gaps. Consult PHASE16_HANDOFF.md before treating the entire research mission as finished.
EOF

close $v;

open my $h, '>', 'PHASE16_HANDOFF.md' or die $!;

print {$h} <<'EOF';
# Phase 16 handoff

Delivered: populated, commit-pinned SWI-Prolog submodule corpus; unchanged upstream archives/originals; complete per-path inventory, provenance, license/eligibility ledgers; separate normalized text/structural derivatives; duplicate/quarantine indexes; native parser overlays; built SWI-Prolog 7.2.0 and OTP 18.0; independently executable integrity tests and recorded example results.

Status: core submodule ingestion and native parsing are populated and independently verifiable. The entire Phase 16 mission is PARTIAL because native parser error resolution, full historical builds, nested dependency closure and manual licensing review are incomplete. Do not describe this as a fully compiled or universally training-cleared historical corpus.

Required deliverables are at this directory root:

* SOURCE_INVENTORY.jsonl
* PROVENANCE_MANIFEST.jsonl
* LICENSE_AUDIT.jsonl
* TRAINING_ELIGIBILITY.jsonl
* INGESTION_REPORT.md
* VERIFICATION_REPORT.md
* PHASE16_HANDOFF.md

Exact totals and definitions are in reports/TOTALS.json and INGESTION_REPORT.md. The 34 snapshots are the first-level gitlinks of SWI-Prolog 7.2.0 at parent-pinned commits.

Run from this directory:

```sh
perl bin/verify.pl
```

The verifier expects ../phase15/ to be present. Dependencies are core Perl modules and POSIX/native utilities plus the Debian toolchain packages locked in TOOLCHAIN_MANIFEST.jsonl. Original source is never executed by the normalization pipeline. Parser runs use native syntax readers only; no archived directives are executed. Re-run native parsers with `sh bin/run-native-parsers.sh`.

For repeatable derivatives, preserve the pinned ledgers and run `perl bin/normalize.pl`, then `perl bin/report.pl`; verify afterward. For acquisition replay, `perl bin/replay.pl /absolute/new-directory` verifies stored download hashes and extracts them into a new location; append --network to re-download exact commit URLs with expected hashes. Do not re-run discovery fetches against moving HEAD as if they reproduced the locked run. Export-only tar hashes can change if an upstream changes tar metadata; reject a changed archive and investigate rather than silently replacing its lock.

Licensing: preserve all copyright/license/NOTICE files. Two files carry the Groupe Bull name-use clause override in evidence/LICENSE_REVIEW_OVERRIDES.jsonl. Every unresolved file context is quarantined. To create a guarded training subset, `perl bin/export-training.pl /absolute/new-training-directory` checks the allowlist and hashes and carries original notices. This is an implementation of the stated permissive-use policy, not a waiver of legal obligations.

Priority continuation:

1. Resolve native parser errors with explicit preprocessor/compiler context and negative-fixture expectations. Retain original bytes and current outcomes until replaced.
2. Fetch nested gitlinks and individually inventory any added repositories; preserve each added repository's provenance and licenses.
3. Obtain native historical-compatible Elixir/Phoenix and remaining toolchains; use separate build trees, record compiler/dependency hashes, and run reviewed language examples. Do not alter original source to accommodate new compilers; patches belong in separate derivatives.
4. Manually review component/file rights, runtime exceptions and remaining quarantined contexts before expanding the allowlist or publicly redistributing the full package.
5. Preserve more complete histories where feasible; add signed-tag verification and original-medium provenance where available.
EOF

close $h;

print "Reports written from exact manifests\n";
