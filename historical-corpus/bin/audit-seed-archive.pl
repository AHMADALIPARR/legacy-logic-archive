#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use File::Find;
use Digest::SHA qw(sha256_hex);
use JSON::PP;

my $root = '/workspace/seed-archive/legacy-logic-archive';
my $j = JSON::PP->new->canonical;

open my $output, '>',
    '/workspace/historical-corpus/evidence/PHASE14_FILE_INVENTORY.jsonl'
    or die $!;

my (%hashes, %urls);
my ($files, $bytes, $executables, $scripts) = (0, 0, 0, 0);

find({
    no_chdir => 1,
    wanted => sub {
        return unless -f $_;

        my $path = $File::Find::name;

        open my $input, '<:raw', $path or die $!;
        local $/;
        my $content = <$input>;

        my $relative = substr($path, length($root) + 1);
        my $hash = sha256_hex($content);

        $files++;
        $bytes += length($content);
        $executables++ if -x $path;
        $scripts++ if $relative =~ m{^bin/};

        push @{$hashes{$hash}}, $relative;

        my $role = $relative =~
            m{^(bin|metadata|sources|research|policy|tests|objects)/}
            ? $1
            : 'documentation';

        print {$output} $j->encode({
            path   => $relative,
            sha256 => $hash,
            bytes  => length($content),
            mode   => sprintf('%04o', (stat($path))[2] & 07777),
            role   => $role,
        }), "\n";

        for my $line (split /\n/, $content) {
            next unless $relative =~ /\.tsv$/;

            while ($line =~ m{(https://[^\s]+)}g) {
                push @{$urls{$1}}, $relative;
            }
        }
    },
}, $root);

close $output;

open my $summary, '>',
    '/workspace/historical-corpus/evidence/PHASE14_AUDIT.json'
    or die $!;

print {$summary} $j->pretty->encode({
    files            => $files,
    bytes            => $bytes,
    executable_files => $executables,
    shell_scripts    => $scripts,

    duplicate_contents => [
        map {
            {
                sha256 => $_,
                paths  => $hashes{$_},
            }
        } sort grep {
            @{$hashes{$_}} > 1
        } keys %hashes
    ],

    repeated_catalog_urls => [
        map {
            {
                url     => $_,
                records => $urls{$_},
            }
        } sort grep {
            @{$urls{$_}} > 1
        } keys %urls
    ],
});
