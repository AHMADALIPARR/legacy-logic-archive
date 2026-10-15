#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

my %ids = map {
    $_ => 1
} qw(
    swi-packages-xpce:src/msw/simx.h
    swi-packages-xpce:src/msw/xpm.h
);

open my $evidence, '>', 'evidence/LICENSE_REVIEW_OVERRIDES.jsonl'
    or die $!;

for my $file (
    qw(
        SOURCE_INVENTORY.jsonl
        LICENSE_AUDIT.jsonl
        TRAINING_ELIGIBILITY.jsonl
    )
) {
    open my $input, '<', $file or die $!;
    open my $output, '>', "$file.new" or die $!;

    while (<$input>) {
        my $record = $j->decode($_);

        if ($ids{$record->{id}}) {
            my $old = $record->{license}
                // $record->{detected_license};

            if ($file eq 'SOURCE_INVENTORY.jsonl') {
                $record->{license} =
                    'LicenseRef-Groupe-Bull-X11-variant';

                $record->{training_status} =
                    'quarantined_pending_review';
            }
            elsif ($file eq 'LICENSE_AUDIT.jsonl') {
                $record->{detected_license} =
                    'LicenseRef-Groupe-Bull-X11-variant';

                $record->{review_status} = 'review_required';
                $record->{redistribution} = 'hold_for_review';

                $record->{file_evidence}{signals} = [
                    'MIT-style-grant',
                    'additional-Groupe-Bull-name-use-clause',
                ];
            }
            else {
                $record->{license} =
                    'LicenseRef-Groupe-Bull-X11-variant';

                $record->{status} = 'quarantined_pending_review';

                $record->{reason} =
                    'Full notice includes an additional Groupe Bull name-use clause; not classified as the exact MIT template. No rights denial inferred; retain for variant-specific review.';

                $record->{policy} = 'phase16-file-grant-review-v2';

                print {$evidence} $j->encode({
                    id                      => $record->{id},
                    sha256                  => $record->{sha256},
                    prior_automated_license => $old,
                    reviewed_license        => $record->{license},
                    status                  => $record->{status},
                    evidence_quote =>
                        'Except as contained in this notice, the name of GROUPE BULL shall not be used in advertising',
                    review =>
                        'textual evidence review; not a legal determination',
                }), "\n";
            }
        }

        print {$output} $j->encode($record), "\n";
    }

    close $output;
    rename "$file.new", $file or die $!;
}

my (%eligible_hashes, %quarantined_hashes);
my ($eligible_count, $quarantined_count) = (0, 0);

open my $eligibility, '<', 'TRAINING_ELIGIBILITY.jsonl'
    or die $!;

open my $quarantine, '>', 'reports/QUARANTINE.jsonl'
    or die $!;

while (<$eligibility>) {
    my $record = $j->decode($_);

    if ($record->{status} eq 'eligible_under_permissive_policy') {
        $eligible_count++;
        $eligible_hashes{$record->{sha256}} = 1;
    }
    else {
        $quarantined_count++;
        $quarantined_hashes{$record->{sha256}} = 1;

        print {$quarantine} $j->encode({
            id     => $record->{id},
            sha256 => $record->{sha256},
            reason => $record->{reason},
        }), "\n";
    }
}

open my $totals_file, '<', 'reports/TOTALS.json'
    or die $!;

local $/;
my $totals = $j->decode(<$totals_file>);

$totals->{training_eligible_file_occurrences} = $eligible_count;
$totals->{unique_training_eligible_files} = scalar keys %eligible_hashes;
$totals->{quarantined_file_occurrences} = $quarantined_count;
$totals->{unique_quarantined_files} = scalar keys %quarantined_hashes;

open my $output, '>', 'reports/TOTALS.json' or die $!;

print {$output} $j->pretty->encode($totals);
