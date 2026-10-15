#!/usr/bin/perl
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->canonical->utf8;

sub rows {
    open my $f, '<', $_[0] or die $!;

    my @records;

    while (my $line = <$f>) {
        push @records, $j->decode($line);
    }

    return @records;
}

sub raw {
    open my $f, '<:raw', $_[0] or die "$_[0]:$!";
    local $/;
    return <$f> // '';
}

my %new;

for (
    qw(
        NATIVE_PROLOG_ISOLATED
        ERLANG18_RECHECK
        ELIXIR105_RECHECK
        ADA_RECHECK
    )
) {
    for (rows("normalized/$_.jsonl")) {
        die 'duplicate recheck' if $new{$_->{id}};
        $new{$_->{id}} = $_;
    }
}

my %failed = map {
    $_->{id} => $_
} rows('evidence/PHASE16_FAILURES.jsonl');

my %summary;

open my $classification, '>', 'PARSER_FAILURE_CLASSIFICATION.jsonl'
    or die $!;

for my $id (sort keys %failed) {
    my $old = $failed{$id};
    my $new = $new{$id} or die "missing $id";

    my $bytes = raw($new->{path});

    die "source changed $id" unless
        sha256_hex($bytes) eq $old->{source_sha256}
        && $new->{source_sha256} eq $old->{source_sha256};

    my ($category, $confidence, $detail) = (
        'unresolved_native_parse_failure',
        'observed',
        'Native parser still reports an error; semantic validity and intended failure are not established.',
    );

    if ($new->{status} eq 'parsed') {
        ($category, $confidence, $detail) = (
            $old->{language} eq 'Prolog'
                ? 'repaired_operator_context'
                : 'repaired_historical_parser_compatibility',
            'verified_parser_result',
            'Native syntax reader passes; this is not full semantic compilation.',
        );
    }
    elsif ($bytes =~ /<%[=]?/ && $id =~ /phoenix/) {
        ($category, $confidence, $detail) = (
            'EEx_template_requires_rendering',
            'source_evidence',
            'Literal EEx delimiters are present. Raw template parsing remains failed; rendering has not been verified.',
        );
    }
    elsif (
        $id =~ /\.pro$/
        && $bytes =~ /(?:^|\n)(?:TEMPLATE\s*=|QT\s*[+]?=|SOURCES\s*[+]?=)/
    ) {
        ($category, $confidence, $detail) = (
            'language_metadata_correction_qmake',
            'source_evidence',
            'qmake project assignments are present; extension-based Prolog classification was incorrect. No qmake build was performed.',
        );
    }
    elsif ($id =~ /(?:\.indent\.pro|util\/indent\.pro)$/) {
        ($category, $confidence, $detail) = (
            'language_metadata_correction_indent_options',
            'source_evidence',
            'Indent configuration, not a Prolog translation unit. Original inventory remains unchanged.',
        );
    }
    elsif (
        $id =~ /libstemmer_c\/Makefile\.pl$/
        && $bytes =~ /^CFLAGS\+=/m
    ) {
        ($category, $confidence, $detail) = (
            'language_metadata_correction_makefile',
            'source_evidence',
            'Makefile assignments and targets; .pl is not a Prolog file here.',
        );
    }
    elsif (
        $old->{language} eq 'Ada'
        && $bytes =~ /\["[0-9A-Fa-f]{4,8}"\]/
    ) {
        ($category, $confidence, $detail) = (
            'historical_wide_character_syntax_unresolved',
            'source_evidence',
            'Bracket wide-character spelling is present; GNAT14 -gnatWb retry still fails. Historical GNAT compilation is pending.',
        );
    }
    elsif (
        $bytes =~ /dg-error|expected.{0,15}(?:syntax|parse).{0,10}error/i
    ) {
        ($category, $confidence, $detail) = (
            'candidate_negative_fixture',
            'provisional',
            'Source contains an expected-error annotation; its correspondence to this diagnostic has not been independently established.',
        );
    }
    elsif (
        $old->{language} eq 'Erlang'
        && $bytes =~ /\?[A-Z_][A-Z0-9_]*/
    ) {
        ($category, $confidence, $detail) = (
            'macro_or_preprocessor_context_unresolved',
            'provisional',
            'Source contains macros; epp_dodger errors remain. This does not establish that macro expansion is the cause.',
        );
    }

    my $record = {
        id                 => $id,
        language           => $old->{language},
        source_sha256      => $old->{source_sha256},
        source_path        => $new->{path},
        prior_status       => $old->{status},
        recheck_status     => $new->{status},
        category           => $category,
        confidence         => $confidence,
        detail             => $detail,
        recheck_artifact    =>
            $new->{ast_path} // $new->{diagnostics_path},
        recheck_artifact_sha256 =>
            $new->{ast_sha256} // $new->{diagnostics_sha256},
        recheck_errors     => $new->{errors},
        source_execution   => JSON::PP::false,
    };

    print {$classification} $j->encode($record), "\n";

    $summary{categories}{$category}++;
    $summary{languages}{$old->{language}}{baseline_failures}++;

    my $outcome = $new->{status} eq 'parsed'
        ? 'repaired'
        : 'unresolved';

    $summary{languages}{$old->{language}}{$outcome}++;
}

close $classification;

open my $output, '>', 'PARSER_RESULTS.jsonl' or die $!;

my ($total, $passed, $regressions) = (0, 0, 0);

for my $language (qw(PROLOG ERLANG ELIXIR ADA)) {
    for my $old (
        rows("../phase16/normalized/NATIVE_$language.jsonl")
    ) {
        my $new = $new{$old->{id}};

        my $evidence_file;

        if ($new) {
            $evidence_file =
                $language eq 'PROLOG'
                    ? 'normalized/NATIVE_PROLOG_ISOLATED.jsonl'
                : $language eq 'ERLANG'
                    ? 'normalized/ERLANG18_RECHECK.jsonl'
                : $language eq 'ELIXIR'
                    ? 'normalized/ELIXIR105_RECHECK.jsonl'
                : 'normalized/ADA_RECHECK.jsonl';
        }
        else {
            $evidence_file =
                "../phase16/normalized/NATIVE_$language.jsonl";
        }

        my $record = {
            id              => $old->{id},
            language        => $old->{language},
            source_sha256   => $old->{source_sha256},
            baseline_status => $old->{status},
            status          => $new ? $new->{status} : $old->{status},
            result_phase    => $new ? 'phase17' : 'phase16',
            evidence_file   => $evidence_file,
        };

        $total++;

        $passed++
            if $record->{status} =~ /^(?:parsed|syntax_passed)$/;

        $regressions++
            if $old->{status} =~ /^(?:parsed|syntax_passed)$/
            && $record->{status} !~ /^(?:parsed|syntax_passed)$/;

        print {$output} $j->encode($record), "\n";
    }
}

$summary{baseline_failures} = scalar keys %failed;
$summary{total_files}       = $total;
$summary{parsed_files}      = $passed;
$summary{remaining_failures} = $total - $passed;
$summary{regressions}       = $regressions;

open my $totals, '>', 'reports/PARSER_TOTALS.json' or die $!;

print {$totals}
    JSON::PP->new->canonical->utf8->pretty->encode(\%summary);
