#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use FindBin;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Copy qw(copy);
use Encode qw(encode);

chdir "$FindBin::Bin/.." or die $!;

my $destination = shift
    or die "usage: export-training.pl NEW_DIRECTORY\n";

die 'destination exists' if -e $destination;

make_path($destination);

my $j = JSON::PP->new->utf8->canonical;
my %allowed;

open my $eligibility, '<', 'TRAINING_ELIGIBILITY.jsonl'
    or die $!;

while (<$eligibility>) {
    my $record = $j->decode($_);

    $allowed{$record->{id}} = $record
        if $record->{status} eq 'eligible_under_permissive_policy';
}

open my $output, '>', "$destination/ALLOWLIST.jsonl"
    or die $!;

open my $inventory, '<', 'SOURCE_INVENTORY.jsonl'
    or die $!;

my $count = 0;

while (<$inventory>) {
    my $record = $j->decode($_);

    next unless my $eligibility = $allowed{$record->{id}};

    die 'unsupported grant'
        unless $eligibility->{license} =~ /^(?:Apache-2\.0|MIT)$/;

    my $path = encode('UTF-8', $record->{original});

    die 'symlink not allowed' if -l $path;

    open my $input, '<:raw', $path or die $!;

    local $/;
    my $bytes = <$input>;

    die 'hash changed' unless
        sha256_hex($bytes) eq $record->{sha256}
        && $record->{sha256} eq $eligibility->{sha256};

    my $target = "$destination/sha256/$record->{sha256}";

    make_path("$destination/sha256");

    unless (-f $target) {
        open my $file, '>:raw', $target or die $!;
        print {$file} $bytes;
        close $file;
    }

    print {$output} $j->encode($record), "\n";
    $count++;
}

open my $provenance, '<', 'PROVENANCE_MANIFEST.jsonl'
    or die $!;

while (<$provenance>) {
    my $record = $j->decode($_);

    for my $evidence (@{$record->{release_license_evidence}}) {
        my $target =
            "$destination/notices/$record->{id}/$evidence->{path}";

        my $directory = $target;
        $directory =~ s{/[^/]+$}{};

        make_path($directory);

        copy(
            "originals/$record->{id}/$evidence->{path}",
            $target
        ) or die $!;
    }
}

print "Exported $count allowlisted occurrences with unchanged notices; all other files excluded. This implements the recorded permissive-use policy, not a jurisdiction-specific legal opinion.\n";
