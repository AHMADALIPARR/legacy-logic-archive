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

open my $input, '<', 'evidence/erlang18-output.tsv';
open my $output, '>', 'normalized/ERLANG18_RECHECK.jsonl';

while (<$input>) {
    chomp;

    my (
        $id,
        $path,
        $source_hash,
        $status,
        $errors,
        $ast_path
    ) = split /\t/;

    open my $ast, '<:raw', $ast_path or die $!;

    local $/;
    my $bytes = <$ast>;

    print {$output} $j->encode({
        id               => $id,
        path             => $path,
        source_sha256    => $source_hash,
        language         => 'Erlang',
        parser           => 'archived OTP18 epp_dodger',
        status           => $status,
        error_markers    => 0 + $errors,
        ast_path         => $ast_path,
        ast_sha256       => sha256_hex($bytes),
        source_execution => JSON::PP::false,
        scope =>
            'historical syntax-tree parse preserving macros; not preprocessor expansion or full compilation',
    }), "\n";
}
