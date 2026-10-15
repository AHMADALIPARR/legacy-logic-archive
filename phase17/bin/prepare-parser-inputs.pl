#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->utf8->canonical;

for my $language (qw(Prolog Erlang Elixir Ada)) {
    open my $input, '<',
        "../phase16/evidence/parser-input-$language.jsonl"
        or die $!;

    open my $output, '>',
        "evidence/parser-input-$language.jsonl"
        or die $!;

    while (<$input>) {
        my $record = $j->decode($_);

        $record->{path} = "../phase16/$record->{path}"
            if $record->{id} =~ m{^phase16/};

        print {$output} $j->encode($record), "\n";
    }
}
