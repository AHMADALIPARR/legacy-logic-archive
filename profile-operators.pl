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

open my $out, '>', 'evidence/PROFILE_OPERATORS.jsonl'
    or die $!;

my $path =
    '../phase15/originals/gprolog-1.4.4/src/EnginePl/oper.c';

open my $input, '<:raw', $path or die $!;

my $body;

{
    local $/;
    $body = <$input>;
}

my $line_number = 0;

for my $line (split /\n/, $body) {
    $line_number++;

    if ($line =~ /ADD_OPER\((\d+),\s*(\w+),\s*"((?:\\.|[^"\\])*)"\)/) {
        my ($priority, $type, $string) = ($1, lc($2), $3);
        my $name = $j->decode('"' . $string . '"');

        print {$out} $j->encode({
            profile         => 'gnu_prolog',
            priority        => 0 + $priority,
            type            => $type,
            name            => $name,
            evidence_path   => $path,
            evidence_sha256 => sha256_hex($body),
            line            => $line_number,
            evidence        => $line,
        }), "\n";
    }
}

my @pce = (
    [1200, 'xfx', ':->'],
    [1200, 'xfx', ':<-'],
    [910,  'xfy', '::'],
    [100,  'xf',  '*'],
    [125,  'xf',  '?'],
    [150,  'xf',  '...'],
    [100,  'xfx', '..'],
);

$path =
    '../phase16/originals/swi-packages-xpce/prolog/boot/pce_expansion.pl';

open $input, '<:raw', $path or die $!;

{
    local $/;
    $body = <$input>;
}

for my $operator (@pce) {
    print {$out} $j->encode({
        profile         => 'xpce_compilation_operators',
        priority        => $operator->[0],
        type            => $operator->[1],
        name            => $operator->[2],
        evidence_path   => $path,
        evidence_sha256 => sha256_hex($body),
        evidence =>
            'literal operator list in push_compile_operators/1; no source call executed',
    }), "\n";
}

my @profiles = (
    [
        'ciao_assertions',
        '../phase15/originals/swi-7.2.0/library/dialect/ciao/assertions.pl',
    ],
    [
        'ciao_assertions',
        '../phase15/originals/swi-7.2.0/library/dialect/ciao/basicmodes.pl',
    ],
    [
        'chr_literal_include',
        '../phase16/originals/swi-packages-chr/chr_op.pl',
    ],
);

for my $spec (@profiles) {
    my ($profile, $source_path) = @$spec;

    open my $source, '<:raw', $source_path or die $!;

    my $source_bytes;

    {
        local $/;
        $source_bytes = <$source>;
    }

    my $line = 0;

    for (split /\n/, $source_bytes) {
        $line++;

        next if /^\s*%/;

        while (/\bop\(\s*(\d+)\s*,\s*(\w+)\s*,\s*([^;]*?)\)\s*\./g) {
            my ($priority, $type, $name) = ($1, $2, $3);

            $name =~ s/^\s+|\s+$//g;
            $name =~ s/^\((.*)\)$/$1/;
            $name =~ s/^'(.*)'$/$1/;

            next if $name =~ /\s|[()]/;

            print {$out} $j->encode({
                profile         => $profile,
                priority        => 0 + $priority,
                type            => $type,
                name            => $name,
                evidence_path   => $source_path,
                evidence_sha256 => sha256_hex($source_bytes),
                line            => $line,
                evidence        => $_,
            }), "\n";
        }
    }
}
