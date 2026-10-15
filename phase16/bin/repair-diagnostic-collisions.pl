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

open my $input, '<', 'normalized/NATIVE_ADA.jsonl'
    or die $!;

open my $output, '>', 'normalized/NATIVE_ADA.jsonl.new'
    or die $!;

while (<$input>) {
    my $record = $j->decode($_);

    open my $old_log, '<:raw', $record->{diagnostics_path}
        or die $!;

    my $bytes;

    {
        local $/;
        $bytes = <$old_log> // '';
    }

    if (sha256_hex($bytes) ne $record->{diagnostics_sha256}) {
        my $log = 'normalized/native/ada/'
            . sha256_hex(
                $record->{id} . "\0" . $record->{source_sha256}
            )
            . '.log';

        my $pid = fork();
        die 'fork' unless defined $pid;

        if (!$pid) {
            open STDOUT, '>', $log or die $!;
            open STDERR, '>&', \*STDOUT;

            exec(
                'gcc',
                "-B$FindBin::Bin/../toolchain/root/usr/libexec/gcc/x86_64-linux-gnu/14/",
                '-c',
                '-gnats',
                $record->{path}
            );

            die 'exec';
        }

        waitpid($pid, 0);
        my $exit_status = $? >> 8;

        open my $new_log, '<:raw', $log or die $!;
        local $/;
        my $new_bytes = <$new_log> // '';

        $record->{diagnostics_path} = $log;
        $record->{diagnostics_sha256} = sha256_hex($new_bytes);
        $record->{exit_status} = $exit_status;
        $record->{status} = $exit_status == 0
            ? 'syntax_passed'
            : 'syntax_errors';

        print STDERR
            "Repaired diagnostic artifact collision: $record->{id}\n";
    }

    print {$output} $j->encode($record), "\n";
}

close $output;

rename(
    'normalized/NATIVE_ADA.jsonl.new',
    'normalized/NATIVE_ADA.jsonl'
) or die $!;
