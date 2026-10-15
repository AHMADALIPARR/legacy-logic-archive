#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

make_path(
    'normalized/prolog-parts',
    'evidence/prolog-inputs',
    'evidence/prolog-logs'
);

open my $input, '<', 'evidence/parser-input-Prolog.jsonl'
    or die $!;

my @jobs;

while (<$input>) {
    my $record = $j->decode($_);
    my $key = sha256_hex($record->{id});

    my $input_path = "evidence/prolog-inputs/$key.jsonl";

    open my $job_input, '>', $input_path or die $!;
    print {$job_input} $j->encode($record), "\n";

    push @jobs, [$key, $input_path];
}

my %running;
my $failed = 0;

while (@jobs || %running) {
    while (@jobs && keys(%running) < 4) {
        my ($key, $input_path) = @{shift @jobs};

        my $pid = fork();
        die 'fork' unless defined $pid;

        if (!$pid) {
            open STDOUT, '>', "evidence/prolog-logs/$key.log";
            open STDERR, '>&', \*STDOUT;

            exec(
                '../phase16/bin/with-tools.sh',
                'swipl',
                '-q',
                '-f', 'none',
                '-s', 'native/parse_prolog.pl',
                '--',
                $input_path,
                "normalized/prolog-parts/$key.jsonl"
            );

            die 'exec';
        }

        $running{$pid} = $key;
    }

    my $pid = wait();

    if ($pid > 0) {
        $failed++ if $? != 0;
        delete $running{$pid};
    }
}

open my $output, '>', 'normalized/NATIVE_PROLOG_ISOLATED.jsonl'
    or die $!;

for my $path (sort glob('normalized/prolog-parts/*.jsonl')) {
    open my $part, '<', $path or die $!;
    print {$output} $_ while <$part>;
}

print "isolated driver failures=$failed\n";

exit($failed ? 1 : 0);
