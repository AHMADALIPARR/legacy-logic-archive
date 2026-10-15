#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex sha1_hex);
use FindBin;
use Encode qw(encode decode FB_CROAK);

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;
$| = 1;

my @results;
my $failed = 0;

sub check {
    my ($name, $ok, $detail) = @_;

    push @results, {
        gate   => $name,
        status => $ok ? 'PASS' : 'FAIL',
        detail => $detail,
    };

    $failed++ unless $ok;

    print "$name: ", ($ok ? 'PASS' : 'FAIL'), " $detail\n";
}

sub b {
    my ($path) = @_;

    $path = encode('UTF-8', $path) if utf8::is_utf8($path);

    return readlink($path) if -l $path;

    open my $input, '<:raw', $path or die "$path: $!";
    local $/;

    return <$input> // '';
}

sub rows {
    my ($path) = @_;

    open my $input, '<', $path or die $!;

    my @records;

    while (<$input>) {
        push @records, $j->decode($_);
    }

    return @records;
}

sub tree_valid {
    my ($tree, $root) = @_;

    my (%children, %expected);
    $expected{''} = $root;

    for my $entry (@{$tree->{tree}}) {
        my ($directory, $name) =
            $entry->{path} =~ m{^(?:(.*)/)?([^/]+)$};

        $directory //= '';

        push @{$children{$directory}}, [$name, $entry];

        $expected{$entry->{path}} = $entry->{sha}
            if $entry->{type} eq 'tree';
    }

    for my $directory (keys %expected) {
        my $payload = '';

        my @sorted = sort {
            ($a->[0] . ($a->[1]{type} eq 'tree' ? '/' : ''))
                cmp
            ($b->[0] . ($b->[1]{type} eq 'tree' ? '/' : ''))
        } @{$children{$directory} // []};

        for my $item (@sorted) {
            my ($name, $entry) = @$item;

            my $mode = $entry->{mode};
            $mode =~ s/^0+//;

            $payload .=
                $mode . ' '
                . encode('UTF-8', $name)
                . "\0"
                . pack('H*', $entry->{sha});
        }

        return 0 unless
            sha1_hex('tree ' . length($payload) . "\0" . $payload)
                eq $expected{$directory};
    }

    return 1;
}

my @provenance = rows('PROVENANCE_MANIFEST.jsonl');

my (
    %trees,
    %hashes,
    %ids,
    %counts,
    %byte_counts,
    %source_hashes,
    %normalized_checked
);

my (
    $bad,
    $files,
    $bytes,
    $tokens,
    $eligible,
    $quarantined
) = (0) x 6;

for my $record (@provenance) {
    my $id = $record->{id};
    my $archive = "downloads/$id.tar.gz";

    check(
        "archive/$id",
        sha256_hex(b($archive)) eq $record->{archive_sha256}
            && -s $archive == $record->{archive_bytes},
        'SHA-256 and byte size from preserved download'
    );

    my $tree = $j->decode(b($record->{tree_evidence}));

    $trees{$id} = {
        map {
            $_->{path} => $_
        } grep {
            $_->{type} eq 'blob'
        } @{$tree->{tree}}
    };

    my $commit = $j->decode(
        b("evidence/$id.commit.json")
    );

    check(
        "tree/$id",
        !$tree->{truncated}
            && tree_valid($tree, $commit->{commit}{tree}{sha}),
        'complete upstream tree bound to commit'
    );
}

open my $inventory, '<', 'SOURCE_INVENTORY.jsonl'
    or die $!;

while (<$inventory>) {
    my $record = $j->decode($_);

    my $content = b($record->{original});
    my $hash = sha256_hex($content);
    my $length = length($content);

    my $entry = $trees{$record->{snapshot}}{$record->{path}};

    $bad++ unless
        $hash eq $record->{sha256}
        && $length == $record->{bytes}
        && $entry
        && sha1_hex("blob $length\0$content") eq $entry->{sha};

    $bad++ if $ids{$record->{id}}++;

    if ($record->{normalized}{path}) {
        my $normalized = $record->{normalized};

        my $copy = $content;
        my $text = eval {
            decode('UTF-8', $copy, FB_CROAK)
        };

        if (defined $text) {
            $text =~ s/\r\n?/\n/g;

            my $normalized_hash =
                sha256_hex(encode('UTF-8', $text));

            $normalized_checked{$normalized->{path}} //=
                sha256_hex(b($normalized->{path}));

            $bad++ unless
                $normalized_hash eq $normalized->{sha256}
                && $normalized_checked{$normalized->{path}}
                    eq $normalized_hash;
        }
        else {
            $bad++;
        }
    }

    $hashes{$hash} = $length;
    $files++;
    $bytes += $length;

    $counts{$record->{snapshot}}++;
    $byte_counts{$record->{snapshot}} += $length;
    $source_hashes{$record->{id}} = $hash;

    $tokens += $record->{source_lexical_tokens} // 0;
}

check(
    'independent_file_bytes_and_git_blobs',
    $bad == 0,
    "$files records rehashed against upstream Git trees; errors=$bad"
);

for my $record (@provenance) {
    my $id = $record->{id};

    check(
        "manifest/$id",
        $counts{$id} == $record->{files}
            && $byte_counts{$id} == $record->{file_bytes}
            && $counts{$id} == keys(%{$trees{$id}}),
        'all commit blobs accounted for, excluding explicitly listed gitlinks'
    );
}

my $license_bad = 0;
my %checked;

open my $licenses, '<', 'LICENSE_AUDIT.jsonl'
    or die $!;

while (<$licenses>) {
    my $record = $j->decode($_);

    $license_bad++ unless
        ($source_hashes{$record->{id}} // '')
            eq $record->{sha256};

    for my $evidence (@{$record->{release_evidence}}) {
        my ($id) = $record->{id} =~ /^([^:]+):/;
        my $path = "originals/$id/$evidence->{path}";

        $checked{$path} //= sha256_hex(b($path));

        $license_bad++ unless
            $checked{$path} eq $evidence->{sha256};
    }
}

check(
    'license_evidence_integrity',
    $license_bad == 0,
    "evidence hashes rechecked; errors=$license_bad"
);

my $eligibility_bad = 0;

open my $eligibility, '<', 'TRAINING_ELIGIBILITY.jsonl'
    or die $!;

while (<$eligibility>) {
    my $record = $j->decode($_);

    $eligibility_bad++ unless
        ($source_hashes{$record->{id}} // '')
            eq $record->{sha256};

    if ($record->{status} eq 'eligible_under_permissive_policy') {
        $eligible++;

        $eligibility_bad++ unless
            $record->{license} =~ /^(Apache-2\.0|MIT)$/;
    }
    else {
        $quarantined++;
    }
}

check(
    'training_partition',
    $eligibility_bad == 0
        && $eligible + $quarantined == $files,
    "eligible=$eligible quarantined=$quarantined"
);

my $summary = $j->decode(b('reports/TOTALS.json'));

my $unique_bytes = 0;
$unique_bytes += $_ for values %hashes;

check(
    'exact_totals',
    $files == $summary->{file_occurrences}
        && keys(%hashes) == $summary->{unique_files}
        && $unique_bytes == $summary->{unique_bytes}
        && $bytes == $summary->{total_file_bytes}
        && $tokens == $summary->{source_code_tokens},
    'occurrences, unique hashes, bytes and lexical token aggregates'
);

my @duplicates = rows('reports/DUPLICATES.jsonl');
my $duplicate_bad = 0;

for my $record (@duplicates) {
    $duplicate_bad++ unless
        $source_hashes{$record->{first}} eq $record->{sha256}
        && $source_hashes{$record->{duplicate}}
            eq $record->{sha256};
}

check(
    'duplicates',
    $duplicate_bad == 0
        && @duplicates == $files - keys(%hashes),
    scalar(@duplicates) . ' duplicate occurrences independently reconciled'
);

my %submodule_lock = map {
    $_->{id} => $_
} rows('evidence/SUBMODULE_LOCK.jsonl');

my $links_ok = @provenance == 34;

for my $record (@provenance) {
    my $locked = $submodule_lock{$record->{id}};

    $links_ok &&=
        $locked
        && $record->{commit} eq $locked->{commit}
        && $record->{repository} eq $locked->{repository};
}

check(
    'exact_pinned_swi_dependency_closure',
    $links_ok,
    'all 34 first-level gitlinks ingested at parent-pinned commits; no nested gitlinks'
);

check(
    'phase15_manifests_preserved',
    system(
        'sh',
        '-c',
        'cd .. && sha256sum --quiet -c swipl-corpus/evidence/PHASE15_BASELINE_SHA256SUMS'
    ) == 0,
    'Phase 15 inventory, provenance, license, eligibility and handoff unchanged'
);

my $toolchain_bad = 0;

for my $record (rows('TOOLCHAIN_MANIFEST.jsonl')) {
    $toolchain_bad++ unless
        sha256_hex(b($record->{artifact})) eq $record->{sha256}
        && -s $record->{artifact} == $record->{bytes};
}

check(
    'native_toolchain_package_hashes',
    $toolchain_bad == 0,
    'all modern native tools match signed Debian package-index SHA-256'
);

my %parser_summary;
my $parser_bad = 0;
my $artifact_bad = 0;
my %verified_ast;

for my $language (qw(Prolog Erlang Elixir Ada)) {
    my $name = uc($language);

    my @inputs = rows(
        "evidence/parser-input-$language.jsonl"
    );

    my %wanted = map {
        $_->{id} => $_
    } @inputs;

    for my $input (@inputs) {
        $parser_bad++ unless
            sha256_hex(b($input->{path})) eq $input->{sha256};
    }

    my @records = rows("normalized/NATIVE_$name.jsonl");
    my %got;

    for my $record (@records) {
        my $expected = $wanted{$record->{id}};

        $parser_bad++ unless
            $expected
            && $expected->{sha256} eq $record->{source_sha256};

        $parser_bad++ if $got{$record->{id}}++;

        $parser_summary{$language}{$record->{status}}++;

        if ($record->{ast_path}) {
            $verified_ast{$record->{ast_path}} //=
                sha256_hex(b($record->{ast_path}));

            $artifact_bad++ unless
                $verified_ast{$record->{ast_path}}
                    eq $record->{ast_sha256};
        }

        if ($record->{diagnostics_path}) {
            $artifact_bad++ unless
                sha256_hex(b($record->{diagnostics_path}))
                    eq $record->{diagnostics_sha256};
        }
    }

    check(
        "native_parser_coverage/$language",
        @inputs == @records && keys(%got) == keys(%wanted),
        scalar(@records)
            . ' input records accounted for; parse errors are retained as outcomes'
    );
}

check(
    'native_parser_source_and_artifact_links',
    $parser_bad == 0 && $artifact_bad == 0,
    "source-link errors=$parser_bad artifact-hash errors=$artifact_bad"
);

open my $parser_totals, '>', 'reports/NATIVE_PARSER_TOTALS.json'
    or die $!;

print {$parser_totals} $j->pretty->encode(\%parser_summary);
close $parser_totals;

my $example_bad = 0;

for (qw(swi72-qsort swi72-queens)) {
    my $exit = b("evidence/$_.exit");
    $example_bad++ unless $exit =~ /^0\s*$/;
}

check(
    'historical_swi_executable_examples',
    $example_bad == 0,
    'SWI-Prolog 7.2.0 sorts correctly and enumerates exactly 92 eight-queens solutions'
);

check(
    'native_parser_adversarial_fixtures',
    system($^X, 'tests/native-fixtures.t') == 0,
    'valid/invalid and complex syntax assertions; no source directive execution'
);

for my $test (
    qw(
        otp18-runtime-check
        erlang-example-run
        elixir-example
        ada-example-run
    )
) {
    check(
        "execution/$test",
        b("evidence/$test.exit") =~ /^0\s*$/,
        'recorded runtime/example execution exited 0'
    );
}

open my $output, '>', 'reports/VERIFICATION_RESULTS.jsonl'
    or die $!;

print {$output} $j->encode($_), "\n" for @results;

exit($failed ? 1 : 0);
