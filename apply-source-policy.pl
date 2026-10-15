# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

my %languages;
my ($tokens, $unique_tokens) = (0, 0);
my %token_seen;
my %normalized_hashes;
my $encoding_unresolved = 0;

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

        if ($file eq 'SOURCE_INVENTORY.jsonl') {
            $record->{training_status} =
                'quarantined_pending_component_review';

            $record->{training_reason} =
                'Historical OpenSSL/SSLeay toolkit terms and file-specific exceptions require component review; explicit file grants are preserved, not replaced by a modern root license.';

            $languages{$record->{language}}++;

            $tokens += $record->{source_lexical_tokens} // 0;

            $unique_tokens += $record->{source_lexical_tokens} // 0
                unless $token_seen{$record->{sha256}}++;

            if ($record->{normalized}{sha256}) {
                $normalized_hashes{
                    $record->{normalized}{sha256}
                } = 1;
            }
            elsif (
                ($record->{normalized}{status} // '')
                    =~ /encoding_unresolved/
            ) {
                $encoding_unresolved++;
            }
        }
        elsif ($file eq 'LICENSE_AUDIT.jsonl') {
            $record->{toolkit_license_evidence} = {
                expression =>
                    'LicenseRef-OpenSSL AND LicenseRef-SSLeay; file-specific grants preserved separately',
                path => 'LICENSE',
                sha256 =>
                    '257fe1b542f846557d0fc938f4206d6c9a6334e2b571fa020e51f96377537120',
            };

            $record->{redistribution} =
                'subject_to_historical_component_terms_review';

            $record->{review_status} =
                'component_review_required';
        }
        else {
            $record->{status} =
                'quarantined_pending_component_review';

            $record->{reason} =
                'No new training eligibility granted in Phase17: historical toolkit-level OpenSSL/SSLeay obligations and component exceptions need separate review.';

            $record->{policy} =
                'phase17-historical-crypto-hold-v1';
        }

        print {$output} $j->encode($record), "\n";
    }

    close $output;

    rename "$file.new", $file or die $!;
}

open my $eligibility, '<', 'TRAINING_ELIGIBILITY.jsonl';
open my $quarantine, '>', 'reports/QUARANTINE.jsonl';

while (<$eligibility>) {
    my $record = $j->decode($_);

    print {$quarantine} $j->encode({
        id     => $record->{id},
        sha256 => $record->{sha256},
        reason => $record->{reason},
    }), "\n";
}

open my $totals_input, '<', 'reports/TOTALS.json';

my $totals;

{
    local $/;
    $totals = $j->decode(<$totals_input>);
}

$totals->{training_eligible_file_occurrences} = 0;
$totals->{unique_training_eligible_files} = 0;

$totals->{quarantined_file_occurrences} =
    $totals->{file_occurrences};

$totals->{unique_quarantined_files} =
    $totals->{unique_files};

$totals->{source_code_tokens} = $tokens;
$totals->{unique_source_code_tokens} = $unique_tokens;
$totals->{languages} = \%languages;

$totals->{unique_normalized_derivatives} =
    scalar keys %normalized_hashes;

$totals->{encoding_unresolved} = $encoding_unresolved;

open my $totals_output, '>', 'reports/TOTALS.json';

print {$totals_output}
    JSON::PP->new->canonical->pretty->encode($totals);
