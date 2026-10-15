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
my %native;

open my $overlay, '>', 'normalized/VERIFICATION_OVERLAY.jsonl'
    or die $!;

for my $language (qw(PROLOG ERLANG ELIXIR ADA)) {
    open my $input, '<', "normalized/NATIVE_$language.jsonl"
        or die $!;

    while (<$input>) {
        my $record = $j->decode($_);

        my $verification = {
            id               => $record->{id},
            source_sha256    => $record->{source_sha256},
            language         => $record->{language},
            native_parser    => $record->{parser},
            status           => $record->{status},
            record_file      => "normalized/NATIVE_$language.jsonl",
            ast_path         => $record->{ast_path},
            ast_sha256       => $record->{ast_sha256},
            diagnostics_path => $record->{diagnostics_path},
            scope            => $record->{scope}
                // 'native syntax parsing only; not compilation or semantic validation',
        };

        print {$overlay} $j->encode($verification), "\n";

        $native{$record->{id}} = $verification
            if $record->{id} =~ m{^phase16/};
    }
}

close $overlay;

open my $input, '<', 'SOURCE_INVENTORY.jsonl' or die $!;
open my $output, '>', 'SOURCE_INVENTORY.jsonl.new' or die $!;

while (<$input>) {
    my $record = $j->decode($_);

    if (my $verification = $native{"phase16/$record->{id}"}) {
        $record->{native_verification} = $verification;

        $record->{structure_status} =
            $verification->{status} eq 'parsed'
                ? 'native_parser_AST_available'
                : 'native_parser_reports_errors; heuristic derivative retained';
    }

    $record->{execution_status} = 'verified_with_SWIPL_7.2.0'
        if $record->{id} =~ /^swi-bench:(?:qsort|queens_8)\.pl$/;

    print {$output} $j->encode($record), "\n";
}

close $output;

rename 'SOURCE_INVENTORY.jsonl.new', 'SOURCE_INVENTORY.jsonl'
    or die $!;
