#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex sha1_hex);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical;

open my $manifest, '<', 'PROVENANCE_MANIFEST.jsonl'
    or die $!;

open my $log, '>', 'evidence/OTP_SUPPLEMENT.jsonl'
    or die $!;

while (<$manifest>) {
    my $record = $j->decode($_);

    next unless $record->{id} =~ /^otp-/;

    for my $path (@{$record->{missing_git_blobs}}) {
        my $destination = "supplemental/$record->{id}/$path";
        my $directory = $destination;
        $directory =~ s{/[^/]+$}{};

        make_path($directory);

        open my $git, '-|',
            'git',
            '-C', 'histories/otp-partial.git',
            'show', "$record->{commit}:$path"
            or die $!;

        local $/;
        my $bytes = <$git>;

        close $git or die 'git show';

        open my $output, '>:raw', $destination or die $!;
        print {$output} $bytes;
        close $output;

        print {$log} $j->encode({
            snapshot => $record->{id},
            path     => $path,
            sha256   => sha256_hex($bytes),
            git_blob => sha1_hex(
                'blob ' . length($bytes) . "\0" . $bytes
            ),
            retrieval =>
                'git show from shallow commit fetch; export omitted this path',
        }), "\n";
    }
}
