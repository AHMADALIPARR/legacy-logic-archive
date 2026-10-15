# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->utf8->canonical;
my %output;

for (qw(Prolog Erlang Elixir Ada)) {
    open $output{$_}, '>', "evidence/parser-input-$_.jsonl"
        or die $!;
}

for my $phase (qw(phase15 phase16)) {
    my $inventory = $phase eq 'phase15'
        ? '../phase15/SOURCE_INVENTORY.jsonl'
        : 'SOURCE_INVENTORY.jsonl';

    open my $input, '<', $inventory or die $!;

    while (<$input>) {
        my $record = $j->decode($_);

        next unless exists $output{$record->{language}};

        my $path = $phase eq 'phase15'
            ? "../phase15/$record->{original}"
            : $record->{original};

        my $parser_input = {
            id       => "$phase/$record->{id}",
            path     => $path,
            sha256   => $record->{sha256},
            language => $record->{language},
        };

        print {$output{$record->{language}}}
            $j->encode($parser_input), "\n";
    }
}
