#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use FindBin;
use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);

chdir "$FindBin::Bin/.." or die $!;

my $root = "$FindBin::Bin/..";
my $j = JSON::PP->new->canonical->utf8;

mkdir 'normalized/native/ada';

open my $input, '<', 'evidence/parser-input-Ada.jsonl'
    or die $!;

open my $output, '>', 'normalized/NATIVE_ADA.jsonl'
    or die $!;

while (<$input>) {
    my $record = $j->decode($_);

    my $key = sha256_hex(
        $record->{id} . "\0" . $record->{sha256}
    );

    my $log = "normalized/native/ada/$key.log";

    my $pid = fork();
    die 'fork' unless defined $pid;

    if (!$pid) {
        open STDOUT, '>', $log or die $!;
        open STDERR, '>&', \*STDOUT;

        exec(
            'timeout',
            '10',
            'gcc',
            "-B$root/toolchain/root/usr/libexec/gcc/x86_64-linux-gnu/14/",
            '-c',
            '-gnats',
            $record->{path}
        );

        die 'exec';
    }

    waitpid($pid, 0);
    my $exit_status = $? >> 8;

    open my $diagnostics, '<:raw', $log or die $!;
    local $/;
    my $bytes = <$diagnostics> // '';

    print {$output} $j->encode({
        id               => $record->{id},
        path             => $record->{path},
        source_sha256    => $record->{sha256},
        language         => 'Ada',
        parser           => 'GNAT 14.2.0 -gnats syntax-only',
        status           => $exit_status == 0
            ? 'syntax_passed'
            : 'syntax_errors',
        exit_status        => $exit_status,
        diagnostics_path   => $log,
        diagnostics_sha256 => sha256_hex($bytes),
        ast_status         => 'not_extracted',
        source_execution   => JSON::PP::false,
    }), "\n";
}
