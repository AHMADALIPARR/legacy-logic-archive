# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

open my $output, '>', 'BUILD_RESULTS.jsonl' or die $!;

for my $stage (
    qw(
        openssl-make
        openssl-test
        openssl-test-historical-time
        openssl-install
        otp18-build
        otp18-crypto-check
        elixir105-make
        elixir105-runtime-check
        elixir105-base-test
        erlang18-recheck
        elixir105-recheck
        prolog-isolated
        ada-recheck
        prolog-fixtures
    )
) {
    my $exit_path = "evidence/$stage.exit";

    open my $exit_file, '<', $exit_path or die $exit_path;

    my $exit_status = <$exit_file>;
    chomp $exit_status;

    my $log = "evidence/$stage.log";
    my $hash;

    if (-f $log) {
        open my $log_file, '<:raw', $log;

        my $digest = Digest::SHA->new(256);
        $digest->addfile($log_file);

        $hash = $digest->hexdigest;
    }

    my $qualification =
        $stage eq 'openssl-test'
            ? 'Unmodified suite fails at current certificate-verification time; preserved explicitly.'
        : $stage eq 'openssl-test-historical-time'
            ? 'Only build-copy CMS verification gets -attime 1434067200; original source unchanged.'
        : $stage =~ /recheck|isolated/
            ? 'Driver completed; individual source failures remain in native JSONL.'
        : 'Observed stage exit; no cross-host or bit-identical runtime rebuild asserted.';

    print {$output} $j->encode({
        stage         => $stage,
        exit_status   => 0 + $exit_status,
        status        => $exit_status == 0 ? 'PASS' : 'FAIL',
        log           => -f $log ? $log : undef,
        log_sha256    => $hash,
        qualification => $qualification,
    }), "\n";
}
