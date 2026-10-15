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

open my $input, '<', 'evidence/elixir105-output.tsv';
open my $output, '>', 'normalized/ELIXIR105_RECHECK.jsonl';

while (<$input>) {
    chomp;

    my (
        $id,
        $path,
        $source_hash,
        $status,
        $ast_path
    ) = split /\t/;

    open my $ast, '<:raw', $ast_path or die $!;

    local $/;
    my $bytes = <$ast>;

    print {$output} $j->encode({
        id               => $id,
        path             => $path,
        source_sha256    => $source_hash,
        language         => 'Elixir',
        parser           => 'historical Elixir1.0.5 on OTP18',
        status           => $status,
        ast_path         => $ast_path,
        ast_sha256       => sha256_hex($bytes),
        source_execution => JSON::PP::false,
        scope =>
            'Code.string_to_quoted/1; ETF preserves {:ok, AST}, {:error, reason} or exception; no source evaluation',
    }), "\n";
}
