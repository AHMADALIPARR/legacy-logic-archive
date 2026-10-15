#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex sha1_hex);
use File::Find;
use File::Path qw(make_path);
use FindBin;
use lib $FindBin::Bin;
use structure;
use Encode qw(decode encode FB_CROAK);

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

sub bytes {
    my ($path) = @_;

    $path = encode('UTF-8', $path) if utf8::is_utf8($path);

    return readlink($path) if -l $path;

    open my $f, '<:raw', $path or die "$path: $!";
    local $/;

    return <$f> // '';
}

sub put {
    my ($handle, $value) = @_;
    print {$handle} $j->encode($value), "\n";
}

my %out;

for (
    qw(
        SOURCE_INVENTORY
        PROVENANCE_MANIFEST
        LICENSE_AUDIT
        TRAINING_ELIGIBILITY
    )
) {
    open $out{$_}, '>', "$_.jsonl" or die $!;
}

open my $der, '>', 'normalized/STRUCTURE.jsonl' or die $!;
open my $dup, '>', 'reports/DUPLICATES.jsonl' or die $!;
open my $quarantine, '>', 'reports/QUARANTINE.jsonl' or die $!;

my (
    %unique,
    %seen,
    %repositories,
    %eligible_unique,
    %languages
);

my (
    $files,
    $total_bytes,
    $tokens,
    $quarantined,
    $eligible,
    $mismatch,
    $missing,
    $gitlinks,
    $normalized
) = (0) x 9;

my (%token_unique, %compiled);
my $unique_tokens = 0;

if (open my $build, '<', 'evidence/example-results.tsv') {
    while (<$build>) {
        chomp;
        my @fields = split /\t/;

        $compiled{$fields[0]} = $fields[1] eq 'PASS'
            ? 'compiled_and_executed; repeat_binary_hash_identical'
            : 'FAILED';
    }
}

my @provenance;

my %extensions = (
    erl    => 'Erlang',
    hrl    => 'Erlang',
    ex     => 'Elixir',
    exs    => 'Elixir',
    pl     => 'Prolog',
    pro    => 'Prolog',
    prolog => 'Prolog',
    adb    => 'Ada',
    ads    => 'Ada',
    ada    => 'Ada',
    pas    => 'Pascal',
    p      => 'Pascal',
    text   => 'Pascal',
    c      => 'C',
    h      => 'C',
    cc     => 'C++',
    cpp    => 'C++',
    f      => 'Fortran',
    f90    => 'Fortran',
    java   => 'Java',
    sh     => 'Shell',
    s      => 'Assembly',
);

for my $provenance_path (sort glob 'evidence/*.provenance.json') {
    my $pr = $j->decode(bytes($provenance_path));
    my $id = $pr->{id};

    $repositories{$pr->{repository}} = 1;

    my $tree = $j->decode(bytes($pr->{tree_evidence}));

    die "truncated tree $id" if $tree->{truncated};

    my %tree_entries = map {
        $_->{path} => $_
    } grep {
        $_->{type} ne 'tree'
    } @{$tree->{tree}};

    my $root = "originals/$id";
    my @paths;

    find({
        no_chdir => 1,
        wanted   => sub {
            push @paths, decode(
                'UTF-8',
                substr($File::Find::name, length($root) + 1),
                FB_CROAK
            ) if -f $_ || -l $_;
        },
    }, $root);

    my $supplemental = "supplemental/$id";

    if (-d $supplemental) {
        find({
            no_chdir => 1,
            wanted   => sub {
                push @paths, decode(
                    'UTF-8',
                    substr(
                        $File::Find::name,
                        length($supplemental) + 1
                    ),
                    FB_CROAK
                ) if -f $_ || -l $_;
            },
        }, $supplemental);
    }

    my @evidence = grep {
        m{(?:^|/)(?:LICEN[CS]E[^/]*|COPYING[^/]*|EPLICENCE|NOTICE[^/]*)$}i
    } sort @paths;

    my @release_evidence = map {
        {
            path   => $_,
            sha256 => sha256_hex(bytes("$root/$_")),
        }
    } @evidence;

    $pr->{release_license_evidence} = \@release_evidence;

    my ($project_files, $project_bytes, $project_bad) = (0, 0, 0);
    my %actual;

    for my $path (sort @paths) {
        $actual{$path} = 1;

        my $original = (-e "$root/$path" || -l "$root/$path")
            ? "$root/$path"
            : "$supplemental/$path";

        my $content = bytes($original);
        my $length  = length($content);
        my $hash    = sha256_hex($content);
        my $blob    = sha1_hex("blob $length\0$content");
        my $entry   = $tree_entries{$path};

        my $verified = (
            $entry
            && $entry->{type} eq 'blob'
            && $entry->{sha} eq $blob
        ) ? 1 : 0;

        $project_bad++ unless $verified;
        $mismatch++ unless $verified;

        $files++;
        $project_files++;
        $project_bytes += $length;
        $total_bytes   += $length;
        $unique{$hash}  = $length;

        my ($extension) = $path =~ /\.([^.\/]+)$/;

        my $language = $extensions{lc($extension // '')}
            // 'non_source';

        $language = 'Perl'
            if $id eq 'openssl-1.0.2c'
            && lc($extension // '') eq 'pl';

        $language = 'non_source'
            if $id eq 'openssl-1.0.2c'
            && $path eq 'util/indent.pro';

        $language = 'non_source'
            if ($extension // '') eq 'text'
            && $id ne 'ucsd-os';

        $language = 'Perl_or_Prolog_unresolved'
            if $language eq 'Prolog'
            && $id !~ /swi|gprolog/;

        $language = 'binary' if index($content, "\0") >= 0;
        $language = 'symlink' if -l $original;

        $languages{$language}++;

        my $head = substr($content, 0, 12000);
        my @signals;

        push @signals, 'Apache-2.0'
            if $head =~ /Licensed under the Apache License, Version 2\.0/i
            || $head =~ /SPDX-License-Identifier:\s*Apache-2\.0\b/;

        push @signals, 'LicenseRef-Erlang-Public-License-1.1'
            if $head =~ /Erlang Public License|ERLANG PUBLIC LICENSE/;

        push @signals, 'GPL-family'
            if $head =~ /GNU General Public License|GNU GENERAL PUBLIC LICENSE/;

        push @signals, 'LGPL-family'
            if $head =~ /GNU (?:Lesser|Library) General Public License/i;

        push @signals, 'BSD-style'
            if $head =~ /Redistribution and use in source and binary forms/;

        push @signals, 'LicenseRef-Groupe-Bull-X11-variant'
            if $head =~ /Except as contained in this notice, the name of GROUPE BULL/;

        push @signals, 'MIT'
            if $head =~ /Permission is hereby granted, free of charge/
            && $head =~ /THE SOFTWARE IS PROVIDED "AS IS"/;

        push @signals, 'LicenseRef-UCSD-noncommercial'
            if $head =~ /educational, research and non-profit|LICENSE-UCSD/;

        my $license = @signals == 1
            ? $signals[0]
            : @signals
                ? 'multiple_signals_review'
                : 'NOASSERTION';

        my $allowed = (
            $verified
            && @signals == 1
            && ($license eq 'Apache-2.0' || $license eq 'MIT')
            && $language !~ /^(?:non_source|binary|symlink|Perl_or_Prolog_unresolved)$/
            && $id ne 'ucsd-os'
            && $path !~ m{(?:^|/)(?:vendor|third.party|test|tests|fixtures)(?:/|$)}i
        );

        my $status = $allowed
            ? 'eligible_under_permissive_policy'
            : 'quarantined_pending_review';

        my $reason = $allowed
            ? 'Explicit file-level permissive grant; retain notices and comply with license. Policy inference of permitted use, not an explicit AI-training grant.'
            : 'Unresolved scope, bundled terms, copyleft obligations, restricted purpose, non-source payload or absent file-level grant; root license alone is insufficient.';

        $allowed ? $eligible++ : $quarantined++;
        $eligible_unique{$hash} = 1 if $allowed;

        my $dialect = $language eq 'Pascal'
            ? 'UCSD Pascal; version requires per-file review'
            : $language eq 'Ada'
                ? 'Ada; revision not inferred from extension'
                : $language eq 'Prolog'
                    ? $pr->{requested_release}
                    : 'unspecified';

        my $record = {
            id                     => "$id:$path",
            snapshot               => $id,
            path                   => $path,
            original               => $original,
            sha256                 => $hash,
            bytes                  => $length,
            git_blob_sha1          => $blob,
            upstream_git_blob_sha1 => $entry ? $entry->{sha} : undef,
            byte_verification      => $verified ? 'passed' : 'FAILED',
            language               => $language,
            dialect                => $dialect,
            repository             => $pr->{repository},
            release                => $pr->{requested_release},
            commit                 => $pr->{commit},
            file_type              => -l $original ? 'symlink' : 'regular',
            license                => $license,
            training_status        => $status,
            compilation_status     => 'not_compiled_individually',
            structure_status       => 'not_applicable',
        };

        if ($language !~ /^(?:non_source|binary|symlink|Perl_or_Prolog_unresolved)$/) {
            my ($entities, $dependencies) =
                Structure::extract($language, $content);

            my $count = () = $content =~ /
                (
                    [A-Za-z_][A-Za-z_0-9]*
                    | [0-9]+
                    | [^\sA-Za-z_0-9]
                )
            /gx;

            $tokens += $count;
            $unique_tokens += $count unless $token_unique{$hash}++;

            my $copy = $content;
            my $text = eval {
                decode('UTF-8', $copy, FB_CROAK)
            };

            if (defined $text) {
                $text =~ s/\r\n?/\n/g;

                my $normalized_bytes = encode('UTF-8', $text);
                my $normalized_hash  = sha256_hex($normalized_bytes);
                my $directory = 'normalized/sha256/'
                    . substr($normalized_hash, 0, 2);

                make_path($directory);

                my $normalized_path = "$directory/$normalized_hash";

                unless (-f $normalized_path) {
                    open my $nf, '>:raw', $normalized_path or die $!;
                    print {$nf} $normalized_bytes;
                    close $nf;
                }

                $record->{normalized} = {
                    path      => $normalized_path,
                    sha256    => $normalized_hash,
                    bytes     => length($normalized_bytes),
                    transform =>
                        'strict UTF-8; CRLF and CR to LF; no semantic rewriting',
                };
            }
            else {
                $record->{normalized} = {
                    status => 'encoding_unresolved; original bytes preserved',
                };
            }

            $record->{source_lexical_tokens} = $count;
            $record->{structure_status} =
                'partial_line_extractor; not full grammar parser';
            $record->{dependencies} = $dependencies;

            put($der, {
                id              => $record->{id},
                original_sha256 => $hash,
                entities        => $entities,
                dependencies    => $dependencies,
                completeness    =>
                    'partial; multiline declarations, macro expansion, comments and dynamic dependencies need native parser review',
            });

            $normalized++;
        }

        if (exists $compiled{$record->{id}}) {
            $record->{compilation_status} = $compiled{$record->{id}};
        }

        put($out{SOURCE_INVENTORY}, $record);

        put($out{LICENSE_AUDIT}, {
            id               => $record->{id},
            sha256           => $hash,
            detected_license => $license,
            file_evidence    => {
                path       => $path,
                sha256     => $hash,
                scan_bytes => length($head),
                signals    => \@signals,
            },
            release_evidence => $pr->{release_license_evidence},
            archival_preservation =>
                'retained_in_restricted_working_archive; public availability is not a universal preservation grant',
            redistribution => $allowed
                ? 'permitted_subject_to_license_conditions'
                : 'hold_for_review',
            review_status => $allowed
                ? 'explicit_file_grant_verified'
                : 'review_required',
        });

        put($out{TRAINING_ELIGIBILITY}, {
            id      => $record->{id},
            sha256  => $hash,
            status  => $status,
            reason  => $reason,
            policy  => 'phase15-permissive-file-grant-v1',
            license => $license,
        });

        unless ($allowed) {
            put($quarantine, {
                id     => $record->{id},
                sha256 => $hash,
                reason => $reason,
            });
        }

        if (exists $seen{$hash}) {
            put($dup, {
                sha256    => $hash,
                first     => $seen{$hash},
                duplicate => $record->{id},
            });
        }
        else {
            $seen{$hash} = $record->{id};
        }
    }

    my @absent = grep {
        $tree_entries{$_}{type} eq 'blob' && !$actual{$_}
    } sort keys %tree_entries;

    $missing += @absent;

    my @links = map {
        {
            path   => $_,
            commit => $tree_entries{$_}{sha},
        }
    } grep {
        $tree_entries{$_}{type} eq 'commit'
    } sort keys %tree_entries;

    $gitlinks += @links;

    $pr->{files}               = $project_files;
    $pr->{file_bytes}          = $project_bytes;
    $pr->{git_blob_mismatches} = $project_bad;
    $pr->{missing_git_blobs}   = \@absent;
    $pr->{unfetched_gitlinks}   = \@links;

    if (-d "histories/$id.git") {
        $pr->{history}      = 'full_git_mirror';
        $pr->{history_path} = "histories/$id.git";
    }

    put($out{PROVENANCE_MANIFEST}, $pr);
    push @provenance, $pr;
}

my $unique_bytes = 0;
$unique_bytes += $_ for values %unique;

my $summary = {
    repositories => scalar keys %repositories,
    snapshots    => scalar @provenance,

    file_occurrences => $files,
    total_file_bytes => $total_bytes,
    unique_files     => scalar keys %unique,
    unique_bytes     => $unique_bytes,

    duplicate_occurrences =>
        $files - scalar(keys %unique),

    quarantined_file_occurrences      => $quarantined,
    training_eligible_file_occurrences => $eligible,
    unique_training_eligible_files    => scalar keys %eligible_unique,

    source_code_tokens        => $tokens,
    unique_source_code_tokens => $unique_tokens,

    token_definition =>
        'ASCII identifier, integer, or each non-whitespace symbol across extension-identified source bytes; includes comments/strings; not model tokens',

    normalized_source_records => $normalized,
    git_blob_mismatches       => $mismatch,
    missing_git_blobs         => $missing,
    unfetched_submodules      => $gitlinks,
    languages                => \%languages,
};

open my $sum, '>', 'reports/TOTALS.json' or die $!;

print {$sum} $j->pretty->encode($summary);
print $j->pretty->encode($summary);

exit(($mismatch || $missing) ? 1 : 0);
