#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use FindBin;
use JSON::PP;
use File::Path qw(make_path);

chdir "$FindBin::Bin/.." or die $!;

my $destination = shift // 'builds/swi-7.2.0';

die 'build destination exists' if -e $destination;

make_path($destination);

system(
    'cp',
    '-R',
    '../historical-corpus/originals/swi-7.2.0/.',
    "$destination/"
) == 0 or die 'copy parent';

open my $lock, '<', 'evidence/SUBMODULE_LOCK.jsonl'
    or die $!;

while (<$lock>) {
    my $record = JSON::PP->new->utf8->decode($_);

    die 'invalid path'
        if $record->{mount_path} =~ m{^/|\.\.};

    make_path("$destination/$record->{mount_path}");

    system(
        'cp',
        '-R',
        "originals/$record->{id}/.",
        "$destination/$record->{mount_path}/"
    ) == 0 or die 'copy submodule';
}

print "$destination assembled without modifying upstream originals\n";
