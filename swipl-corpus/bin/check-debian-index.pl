#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use Digest::SHA;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $release =
    'apt/lists/deb.debian.org_debian_dists_trixie_InRelease';

open my $release_file, '<', $release or die $!;

my $text;

{
    local $/;
    $text = <$release_file>;
}

my ($block) = $text =~ /^SHA256:\n(.*?)(?=^\S|\z)/ms
    or die 'no signed SHA256 block';

my ($expected, $size) = $block =~
    /^\s*([a-f0-9]{64})\s+(\d+)\s+main\/binary-amd64\/Packages\s*$/m
    or die 'no amd64 Packages digest';

my ($path) = glob 'apt/lists/*Packages.lz4';

open my $index, '-|',
    '/usr/lib/apt/apt-helper', 'cat-file', $path
    or die $!;

binmode $index;

my $digest = Digest::SHA->new(256);
my $bytes = 0;

while (read($index, my $chunk, 65536)) {
    $digest->add($chunk);
    $bytes += length($chunk);
}

close $index or die 'index reader';

my $hash = $digest->hexdigest;

die 'signed index HASH FAILED' unless
    $hash eq $expected && $bytes == $size;

print JSON::PP->new->canonical->encode({
    gate    => 'signed_debian_release_to_package_index',
    status  => 'PASS',
    sha256  => $hash,
    bytes   => $bytes,
    release => $release,
    signature_evidence => 'evidence/debian-signature.log',
    index => $path,
    scope =>
        'decompressed index SHA256/bytes match signed InRelease; .deb archives separately match index',
}), "\n";
