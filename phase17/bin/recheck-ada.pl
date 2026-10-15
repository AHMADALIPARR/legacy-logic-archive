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

mkdir 'normalized/ada';

open my $input, '<', 'evidence/PHASE16_FAILURES.jsonl'
    or die $!;

open my $output, '>', 'normalized/ADA_RECHECK.jsonl'
    or die $!;

while (<$input>) {
    my $record = $j->decode($_);

    next unless $record->{language} eq 'Ada';

    my $log = 'normalized/ada/'
        . sha256_hex($record->{id})
        . '.log';

    my $path = $record->{path};

    $path = "../phase16/$path"
        if $record->{id} =~ m{^phase16/};

    my $pid = fork();
    die 'fork' unless defined $pid;

    if (!$pid) {
        open STDOUT, '>', $log;
        open STDERR, '>&', \*STDOUT;

        exec(
            'gcc',
            "-B$FindBin::Bin/../../phase16/toolchain/root/usr/libexec/gcc/x86_64-linux-gnu/14/",
            '-c',
            '-gnats',
            '-gnatWb',
            $path
        );

        die 'exec';
    }

    waitpid($pid, 0);

    my $exit_status = $? >> 8;

    open my $diagnostics, '<:raw', $log or die $!;

    my $bytes;

    {
        local $/;
        $bytes = <$diagnostics> // '';
    }

    print {$output} $j->encode({
        id               => $record->{id},
        source_sha256    => $record->{source_sha256},
        path             => $path,
        language         => 'Ada',
        profile =>
            'GNAT14 syntax-only with bracket wide-character encoding -gnatWb',
        status => $exit_status == 0
            ? 'syntax_passed'
            : 'syntax_errors',
        exit_status        => $exit_status,
        diagnostics_path   => $log,
        diagnostics_sha256 => sha256_hex($bytes),
        source_execution   => JSON::PP::false,
    }), "\n";
}
