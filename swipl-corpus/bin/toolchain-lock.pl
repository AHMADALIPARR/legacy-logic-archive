#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use FindBin;
use JSON::PP;
use Digest::SHA;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical;
my (%wanted, %index);

for my $deb (glob 'toolchain/debs/*.deb') {
    open my $metadata, '-|',
        'dpkg-deb', '-f', $deb,
        'Package', 'Version', 'Architecture'
        or die $!;

    my @values = <$metadata>;
    close $metadata or die 'dpkg-deb';

    chomp @values;
    s/^\w+:\s*// for @values;

    my $key = join('|', @values);
    $wanted{$key} = $deb;
}

my ($index_path) = glob 'apt/lists/*Packages.lz4';

open my $packages, '-|',
    '/usr/lib/apt/apt-helper', 'cat-file', $index_path
    or die $!;

{
    local $/ = "\n\n";

    while (<$packages>) {
        my %fields;

        while (/^(Package|Version|Architecture|Filename|SHA256|Size): (.+)$/mg) {
            $fields{$1} = $2;
        }

        my $key = join(
            '|',
            map { $fields{$_} // '' }
                qw(Package Version Architecture)
        );

        $index{$key} = \%fields if exists $wanted{$key};
    }
}

close $packages or die 'apt index';

open my $output, '>', 'TOOLCHAIN_MANIFEST.jsonl'
    or die $!;

for my $key (sort keys %wanted) {
    my $package = $index{$key}
        or die "not in signed index $key";

    my $deb = $wanted{$key};

    open my $archive, '<:raw', $deb or die $!;

    my $digest = Digest::SHA->new(256);
    $digest->addfile($archive);

    my $hash = $digest->hexdigest;

    die "package HASH FAILED $deb" unless
        $hash eq $package->{SHA256}
        && -s $deb == $package->{Size};

    print {$output} $j->encode({
        package      => $package->{Package},
        version      => $package->{Version},
        architecture => $package->{Architecture},
        artifact     => $deb,
        sha256       => $hash,
        bytes        => 0 + $package->{Size},
        url =>
            "https://deb.debian.org/debian/$package->{Filename}",
        trust =>
            'Debian signed InRelease -> Packages index -> package SHA256; apt-verified',
        role =>
            'modern verification/build tool; excluded from historical source corpus totals',
        extraction =>
            'dpkg-deb -x; no maintainer scripts run; workspace only',
    }), "\n";
}

print scalar(keys %wanted),
    " packages independently matched signed-index SHA-256 values\n";
