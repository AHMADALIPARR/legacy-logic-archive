#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;
my @results;
my $failures = 0;

sub check {
    my ($gate, $ok, $detail) = @_;

    push @results, {
        gate   => $gate,
        status => $ok ? 'PASS' : 'FAIL',
        detail => $detail,
    };

    $failures++ unless $ok;

    print "$gate ", ($ok ? 'PASS' : 'FAIL'), " $detail\n";
}

sub rows {
    open my $input, '<', $_[0] or die $!;

    my @records;

    while (my $line = <$input>) {
        push @records, $j->decode($line);
    }

    return @records;
}

sub raw {
    open my $input, '<:raw', $_[0] or die "$_[0]: $!";
    local $/;
    return <$input> // '';
}

my $bad = 0;
my $lines = 0;

for my $path (
    glob('*.jsonl'),
    glob('normalized/inherited/*.jsonl'),
    glob('reports/*.jsonl')
) {
    open my $input, '<', $path or die $!;

    while (my $line = <$input>) {
        $lines++;

        my $value = eval {
            $j->decode($line)
        };

        $bad++ if $@ || ref($value) ne 'HASH';
    }
}

check(
    'strict_jsonl_deliverables',
    !$bad,
    "$lines records; invalid=$bad"
);

my @classifications = rows('PARSER_FAILURE_CLASSIFICATION.jsonl');

my %baseline = map {
    $_->{id} => $_
} rows('evidence/PHASE16_FAILURES.jsonl');

my %seen;
my $repaired = 0;
$bad = 0;

for my $record (@classifications) {
    $bad++ if
        $seen{$record->{id}}++
        || !$baseline{$record->{id}}
        || $record->{source_sha256}
            ne $baseline{$record->{id}}{source_sha256};

    $repaired++ if $record->{recheck_status} eq 'parsed';
}

check(
    'baseline_failure_classification',
    !$bad && @classifications == keys(%baseline),
    scalar(@classifications)
        . " baseline failures covered exactly once; $repaired repaired"
);

my $native_count = 0;
$bad = 0;

for my $path (
    qw(
        normalized/NATIVE_PROLOG_ISOLATED.jsonl
        normalized/ERLANG18_RECHECK.jsonl
        normalized/ELIXIR105_RECHECK.jsonl
        normalized/ADA_RECHECK.jsonl
    )
) {
    for my $record (rows($path)) {
        $native_count++;

        $bad++ unless
            sha256_hex(raw($record->{path}))
                eq $record->{source_sha256}
            && !$record->{source_execution};

        for my $kind (qw(ast diagnostics)) {
            if ($record->{"${kind}_path"}) {
                $bad++ unless
                    sha256_hex(raw($record->{"${kind}_path"}))
                        eq $record->{"${kind}_sha256"};
            }
        }
    }
}

check(
    'native_source_and_artifact_hashes',
    !$bad,
    "$native_count native rechecks independently rehashed; errors=$bad"
);

my @all = rows('PARSER_RESULTS.jsonl');

my $passed = grep {
    $_->{status} =~ /^(?:parsed|syntax_passed)$/
} @all;

my $regressions = grep {
    $_->{baseline_status} =~ /^(?:parsed|syntax_passed)$/
        && $_->{status} !~ /^(?:parsed|syntax_passed)$/
} @all;

my $parser_totals = $j->decode(
    raw('reports/PARSER_TOTALS.json')
);

check(
    'parser_aggregate',
    @all == 13902
        && $passed == $parser_totals->{parsed_files}
        && $parser_totals->{remaining_failures} == @all - $passed
        && !$regressions,
    'files=' . scalar(@all)
        . " passes=$passed"
        . ' unresolved=' . (@all - $passed)
        . " regressions=$regressions"
);

$bad = 0;
my $replayed = 0;

for my $record (rows('SOURCE_INVENTORY.jsonl')) {
    $replayed++;

    $bad++ unless
        sha256_hex(
            raw("/workspace/native-recheck-replay-check/$record->{original}")
        ) eq $record->{sha256};
}

check(
    'offline_source_replay',
    !$bad,
    "$replayed replayed file hashes; errors=$bad"
);

check(
    'baseline_ledgers_preserved',
    system(
        'sh',
        '-c',
        'cd /workspace && sha256sum -c native-recheck/evidence/BASELINE_LEDGER_SHA256SUMS > native-recheck/evidence/BASELINE_FINAL_CHECK.txt 2>&1'
    ) == 0,
    'all locked Phase15/16 ledger bytes unchanged'
);

check(
    'runtime_hashes',
    system(
        'sh',
        '-c',
        'sha256sum -c evidence/RUNTIME_SHA256SUMS > evidence/RUNTIME_FINAL_CHECK.txt 2>&1'
    ) == 0,
    'built runtime artifact hashes'
);

for my $stage (
    qw(
        source-verification
        prolog-fixtures
        otp18-crypto-check
        elixir105-runtime-check
        elixir105-base-test
        openssl-test-historical-time
    )
) {
    my $exit_status = raw("evidence/$stage.exit");

    check(
        "execution/$stage",
        $exit_status =~ /^0\s*$/,
        'exit status recorded; logs preserved'
    );
}

check(
    'unmodified_openssl_failure_visible',
    raw('evidence/openssl-test.exit') =~ /^2\s*$/,
    'current-time certificate test failure explicitly retained; historical-time run is separate'
);

open my $output, '>', 'reports/VERIFICATION_RESULTS.jsonl'
    or die $!;

print {$output} $j->encode($_), "\n" for @results;

exit($failures ? 1 : 0);
