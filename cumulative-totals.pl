# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->utf8;

my (
    %hashes,
    %repositories,
    %snapshots,
    %eligible,
    %held
);

my (
    $files,
    $bytes,
    $tokens,
    $unique_tokens,
    $eligible_contexts,
    $quarantined_contexts
) = (0) x 6;

for my $phase (qw(../phase15 ../phase16 .)) {
    open my $input, '<', "$phase/SOURCE_INVENTORY.jsonl"
        or die $!;

    while (my $line = <$input>) {
        my $record = $j->decode($line);

        $files++;
        $bytes += $record->{bytes};
        $tokens += $record->{source_lexical_tokens} // 0;

        $unique_tokens += $record->{source_lexical_tokens} // 0
            unless exists $hashes{$record->{sha256}};

        $hashes{$record->{sha256}} = $record->{bytes};

        $repositories{$record->{repository}} = 1;
        $snapshots{"$phase/$record->{snapshot}"} = 1;

        if (
            $record->{training_status}
                eq 'eligible_under_permissive_policy'
        ) {
            $eligible_contexts++;
            $eligible{$record->{sha256}} = 1;
        }
        else {
            $quarantined_contexts++;
            $held{$record->{sha256}} = 1;
        }
    }
}

my $unique_bytes = 0;
$unique_bytes += $_ for values %hashes;

my $totals = {
    repositories => scalar(keys %repositories),
    snapshots    => scalar(keys %snapshots),

    file_occurrences => $files,
    unique_files     => scalar(keys %hashes),

    total_file_bytes => $bytes,
    unique_bytes     => $unique_bytes,

    duplicate_occurrences =>
        $files - scalar(keys %hashes),

    source_code_tokens        => $tokens,
    unique_source_code_tokens => $unique_tokens,

    conditionally_training_eligible_file_occurrences =>
        $eligible_contexts,

    unique_conditionally_training_eligible_files =>
        scalar(keys %eligible),

    quarantined_file_occurrences => $quarantined_contexts,
    unique_quarantined_files     => scalar(keys %held),

    note =>
        'Eligibility is the inherited policy classification per source context, not legal clearance or proof of a training run; tokens are documented lexical units, not model tokenizer tokens.',
};

open my $output, '>', 'reports/CUMULATIVE_TOTALS.json'
    or die $!;

print {$output}
    JSON::PP->new->canonical->pretty->encode($totals);
