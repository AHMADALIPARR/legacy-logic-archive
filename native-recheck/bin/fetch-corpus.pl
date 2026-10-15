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
    open my $f, '<:raw', $_[0] or die "$!: $_[0]";
    local $/;
    return <$f>;
}

sub get {
    my ($url, $out) = @_;

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
        '--dump-header', "$out.headers",
        '--output', "$out.part",
        $url
    ) == 0 or die "download failed $url";

    rename "$out.part", $out or die $!;
}

my @targets = (
    ['otp-17.5',        'erlang/otp',                 'OTP-17.5',          'Erlang'],
    ['otp-18.0',        'erlang/otp',                 'OTP-18.0',          'Erlang'],
    ['swi-7.2.0',       'SWI-Prolog/swipl-devel',     'V7.2.0',            'Prolog'],
    ['gprolog-1.4.4',   'didoudiaz/gprolog',          'v1.4.4',            'Prolog'],
    ['elixir-1.0.5',    'elixir-lang/elixir',         'v1.0.5',            'Elixir'],
    ['phoenix-1.0.0',   'phoenixframework/phoenix',   'v1.0.0',            'Elixir'],
    ['gnat-4.2.0',      'gcc-mirror/gcc',            'releases/gcc-4.2.0','Ada'],
    ['spark-0.3-draft', 'AdaCore/spark2014',         '0.3_draft',         'Ada/SPARK'],
    ['ucsd-os',         'jdykstra/ucsd-psystem-os',   'HEAD',              'UCSD Pascal'],
);

open my $log, '>>', 'evidence/fetch-attempts.jsonl' or die $!;

for my $target (@targets) {
    my ($id, $repo, $tag, $language) = @$target;

    next if -f "evidence/$id.provenance.json";

    eval {
        my $start = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
        my $api = "https://api.github.com/repos/$repo";

        get(
            "$api/commits/$tag",
            "evidence/$id.commit.json"
        );

        my $commit = $json->decode(
            readfile("evidence/$id.commit.json")
        );

        my $sha = $commit->{sha};
        die 'invalid commit' unless $sha =~ /^[a-f0-9]{40}$/;

        get(
            "$api/git/trees/$sha?recursive=1",
            "evidence/$id.tree.json"
        );

        my $url = "https://codeload.github.com/$repo/tar.gz/$sha";

        get($url, "downloads/$id.tar.gz");

        system('gzip', '-t', "downloads/$id.tar.gz") == 0
            or die 'gzip integrity';

        open my $list, '-|', 'tar', '-tzf', "downloads/$id.tar.gz"
            or die $!;

        while (<$list>) {
            chomp;

            die "unsafe archive path $_"
                if m{^/|(?:^|/)\.\.(?:/|$)|[\x00-\x1f]};
        }

        close $list or die 'tar list failed';

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
            id                     => $id,
            repository             => "https://github.com/$repo",
            requested_release      => $tag,
            commit                 => $sha,
            commit_date            => $commit->{commit}{committer}{date},
            download_url           => $url,
            download_started_utc   => $start,
            download_completed_utc => strftime(
                '%Y-%m-%dT%H:%M:%SZ', gmtime
            ),
            archive_sha256 => sha256_hex(
                readfile("downloads/$id.tar.gz")
            ),
            archive_bytes  => -s "downloads/$id.tar.gz",
            primary_language => $language,
            history          => 'commit_snapshot_only',
            submodules       => 'not_fetched; gitlinks recorded in tree evidence',
            tree_evidence    => "evidence/$id.tree.json",
            signature_status => 'not_verified',
            provenance_strength =>
                'HTTPS upstream API commit and independent Git blob comparison; not signed release verification',
        };

        open my $provenance, '>', "evidence/$id.provenance.json"
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
