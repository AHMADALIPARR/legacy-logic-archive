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

open my $output, '>', 'evidence/INHERITED_FORMAT_AUDIT.jsonl'
    or die $!;

for my $path (
    qw(
        ../phase16/BUILD_RESULTS.jsonl
        ../phase16/reports/VERIFICATION_RESULTS.jsonl
    )
) {
    open my $input, '<:raw', $path or die $!;

    my ($lines, $bad, $body) = (0, 0, '');

    while (<$input>) {
        $body .= $_;

        next unless /\S/;

        $lines++;

        eval {
            $j->decode($_);
        };

        $bad++ if $@;
    }

    print {$output} $j->encode({
        path                    => $path,
        sha256                  => sha256_hex($body),
        nonblank_physical_lines => $lines,
        non_json_record_lines   => $bad,

        strict_jsonl => $bad
            ? JSON::PP::false
            : JSON::PP::true,

        action =>
            'original preserved; jq -c normalized derivative under normalized/inherited/',

        finding =>
            'pretty JSON text sequence is valid JSON input to jq but not strict JSONL',
    }), "\n";
}
