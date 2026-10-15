# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

for my $language (qw(prolog erlang elixir)) {
    my $extension = $language eq 'prolog'
        ? 'pl'
        : $language eq 'erlang'
            ? 'erl'
            : 'ex';

    open my $output, '>', "tests/$language-input.jsonl"
        or die $!;

    for my $path (
        "tests/${language}_fixture.$extension",
        "tests/invalid_$language.$extension"
    ) {
        open my $input, '<:raw', $path or die $!;
        local $/;
        my $bytes = <$input>;

        print {$output} JSON::PP->new->canonical->encode({
            id     => $path,
            path   => $path,
            sha256 => sha256_hex($bytes),
        }), "\n";
    }
}
