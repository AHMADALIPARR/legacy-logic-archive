#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $json = JSON::PP->new->canonical;

sub readfile {
    open my $input, '<:raw', $_[0] or die "$!: $_[0]";
    local $/;
    return <$input>;
}

sub get {
    my ($url, $output) = @_;

    system(
        'curl',
        '--fail',
        '--location',
        '--proto', '=https',
        '--proto-redir', '=https',
        '--retry', '1',
        '--connect-timeout', '15',
        '--max-time', '300',
        '--silent',
        '--show-error',
        '--dump-header', "$output.headers",
        '--output', "$output.part",
        $url
    ) == 0 or die "download failed $url";

    rename "$output.part", $output or die $!;
}

my @targets = (
    [
        'openssl-1.0.2c',
        'openssl/openssl',
        'OpenSSL_1_0_2c',
        'C',
    ],
);

open my $log, '>>', 'evidence/fetch-attempts.jsonl'
    or die $!;

for my $target (@targets) {
    my ($id, $repository, $tag, $language) = @$target;

    next if -f "evidence/$id.provenance.json";

    eval {
        my $start = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
        my $api = "https://api.github.com/repos/$repository";

        get(
            "$api/commits/$tag",
            "evidence/$id.commit.json"
        );

        my $commit = $json->decode(
            readfile("evidence/$id.commit.json")
        );

        my $sha = $commit->{sha};

        die 'invalid commit'
            unless $sha =~ /^[a-f0-9]{40}$/;

        get(
            "$api/git/trees/$sha?recursive=1",
            "evidence/$id.tree.json"
        );

        my $url =
            "https://codeload.github.com/$repository/tar.gz/$sha";

        get($url, "downloads/$id.tar.gz");

        system('gzip', '-t', "downloads/$id.tar.gz") == 0
            or die 'gzip integrity';

        open my $listing, '-|',
            'tar', '-tzf', "downloads/$id.tar.gz"
            or die $!;

        while (<$listing>) {
            chomp;

            die "unsafe archive path $_"
                if m{^/|(?:^|/)\.\.(?:/|$)|[\x00-\x1f]};
        }

        close $listing or die 'tar list failed';

        mkdir "originals/$id";

        system(
            'tar',
            '-xzf', "downloads/$id.tar.gz",
            '--strip-components=1',
            '--no-same-owner',
            '--no-same-permissions',
            '-C', "originals/$id"
        ) == 0 or die 'extraction';

        my $record = {
            id                => $id,
            repository        => "https://github.com/$repository",
            requested_release => $tag,
            commit            => $sha,
            commit_date       => $commit->{commit}{committer}{date},
            download_url      => $url,
            download_started_utc => $start,
            download_completed_utc =>
                strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
            archive_sha256 =>
                sha256_hex(readfile("downloads/$id.tar.gz")),
            archive_bytes    => -s "downloads/$id.tar.gz",
            primary_language => $language,
            history          => 'commit_snapshot_only',
            submodules =>
                'not_fetched; gitlinks recorded in tree evidence',
            tree_evidence    => "evidence/$id.tree.json",
            signature_status => 'not_verified',
            provenance_strength =>
                'HTTPS upstream API commit and independent Git blob comparison; not signed release verification',
        };

        open my $provenance, '>',
            "evidence/$id.provenance.json"
            or die $!;

        print {$provenance} $json->encode($record), "\n";
        close $provenance;

        print "$id $sha downloaded ",
            $record->{archive_bytes}, " bytes\n";

        print {$log} $json->encode({
            id     => $id,
            status => 'downloaded',
            utc    => $record->{download_completed_utc},
        }), "\n";
    };

    if ($@) {
        print STDERR "$id: $@\n";

        print {$log} $json->encode({
            id     => $id,
            status => 'failed',
            error  => "$@",
        }), "\n";
    }
}
