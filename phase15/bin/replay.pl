# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Copy qw(copy);

my $base = "$FindBin::Bin/..";

my $destination = shift
    or die "usage: replay.pl NEW_EMPTY_DIRECTORY [--network]\n";

my $network = shift // 'offline';

die 'destination already exists' if -e $destination;

make_path($destination);

my $j = JSON::PP->new->utf8;

sub digest {
    open my $input, '<:raw', $_[0] or die $!;

    my $digest = Digest::SHA->new(256);
    $digest->addfile($input);

    return $digest->hexdigest;
}

open my $provenance, '<', "$base/PROVENANCE_MANIFEST.jsonl"
    or die $!;

while (<$provenance>) {
    my $record = $j->decode($_);
    my $id = $record->{id};

    make_path(
        "$destination/downloads",
        "$destination/originals/$id"
    );

    my $archive = "$destination/downloads/$id.tar.gz";

    if ($network eq '--network') {
        system(
            'curl',
            '--fail',
            '--location',
            '--proto', '=https',
            '--proto-redir', '=https',
            '--connect-timeout', '15',
            '--max-time', '300',
            '--output', "$archive.part",
            $record->{download_url}
        ) == 0 or die "download $id";

        rename "$archive.part", $archive or die $!;
    }
    else {
        copy(
            "$base/downloads/$id.tar.gz",
            $archive
        ) or die $!;
    }

    die "HASH FAILURE $id"
        unless digest($archive) eq $record->{archive_sha256};

    open my $listing, '-|', 'tar', '-tzf', $archive
        or die $!;

    while (<$listing>) {
        die 'unsafe path'
            if m{^/|(?:^|/)\.\.(?:/|$)|[\x00-\x08\x0b-\x1f]};
    }

    close $listing or die 'tar list';

    system(
        'tar',
        '-xzf', $archive,
        '--strip-components=1',
        '--no-same-owner',
        '--no-same-permissions',
        '-C', "$destination/originals/$id"
    ) == 0 or die 'tar extraction';

    print "replayed $id $record->{archive_sha256}\n";
}

open my $supplement, '<', "$base/evidence/OTP_SUPPLEMENT.jsonl"
    or die $!;

while (<$supplement>) {
    my $record = $j->decode($_);

    my $relative =
        "supplemental/$record->{snapshot}/$record->{path}";

    my $output = "$destination/$relative";
    my $directory = $output;
    $directory =~ s{/[^/]+$}{};

    make_path($directory);

    copy("$base/$relative", $output) or die $!;

    die 'supplement hash failure'
        unless digest($output) eq $record->{sha256};
}

print "OTP supplemental blobs copied and verified; gitlinks remain explicitly unfetched. All original archive bytes and extracted source bytes have been preserved.\n";
