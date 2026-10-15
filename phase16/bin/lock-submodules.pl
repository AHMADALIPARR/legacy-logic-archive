# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

open my $modules, '<',
    '../phase15/originals/swi-7.2.0/.gitmodules'
    or die $!;

my (%urls, $path);

while (<$modules>) {
    $path = $1 if /path\s*=\s*(\S+)/;
    $urls{$path} = $1 if /url\s*=\s*(\S+)/;
}

open my $tree_file, '<',
    '../phase15/evidence/swi-7.2.0.tree.json'
    or die $!;

local $/;
my $tree = $j->decode(<$tree_file>);

open my $output, '>', 'evidence/SUBMODULE_LOCK.jsonl'
    or die $!;

for my $entry (@{$tree->{tree}}) {
    next unless $entry->{type} eq 'commit';

    my $url = $urls{$entry->{path}}
        or die 'missing submodule URL';

    $url =~ s{^\.\./}{https://github.com/SWI-Prolog/};
    $url =~ s/\.git$//;

    my $id = $entry->{path};
    $id =~ s{/}{-}g;

    print {$output} $j->encode({
        id                => "swi-$id",
        repository        => $url,
        commit            => $entry->{sha},
        requested_release => 'SWI-Prolog-7.2.0-gitlink',
        mount_path        => $entry->{path},
        parent_commit     => '6442d29038b0e1ed413e2f1dfe8086b812777e7d',
        primary_language  => 'Prolog',
    }), "\n";
}
