# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use JSON::PP;
use Test::More;
use FindBin;

chdir "$FindBin::Bin/.." or die $!;

my $j = JSON::PP->new->utf8;
my %records;

for my $language (qw(prolog erlang elixir)) {
    open my $input, '<', "tests/$language-output.jsonl"
        or die $!;

    while (<$input>) {
        my $record = $j->decode($_);
        $records{$record->{id}} = $record;
    }
}

for my $language (qw(prolog erlang elixir)) {
    my $extension = $language eq 'prolog'
        ? 'pl'
        : $language eq 'erlang'
            ? 'erl'
            : 'ex';

    is(
        $records{"tests/${language}_fixture.$extension"}{status},
        'parsed',
        "$language multiline valid fixture parsed"
    );

    is(
        $records{"tests/invalid_$language.$extension"}{status},
        'parse_errors',
        "$language malformed fixture rejected"
    );
}

my $prolog = $records{'tests/prolog_fixture.pl'};
my @terms = @{$prolog->{terms}};

ok(
    grep({
        ($_->{entity}{name} // '') eq 'quoted predicate'
            && ($_->{entity}{arity} // 0) == 2
    } @terms),
    'quoted Prolog predicate arity preserved'
);

ok(
    grep({
        ($_->{entity}{kind} // '') eq 'dcg_rule'
    } @terms),
    'DCG structure recognized'
);

ok(
    grep({
        $_->{term} =~ /links/
    } @terms),
    'literal custom operator parsed without executing clauses'
);

my $erlang = $records{'tests/erlang_fixture.erl'};

ok(
    grep({
        $_->{kind} eq 'function'
            && $_->{name} eq 'run'
            && $_->{arity} == 1
    } @{$erlang->{entities}}),
    'Erlang macro-containing function recognized'
);

ok(
    grep({
        $_->{kind} eq 'attribute'
            && $_->{name} eq 'include'
    } @{$erlang->{entities}}),
    'Erlang include declaration retained without opening include'
);

my $elixir = $records{'tests/elixir_fixture.ex'};

ok(
    grep({
        $_->{kind} eq 'defmacro'
    } @{$elixir->{entities}}),
    'Elixir macro definition recognized'
);

ok(
    grep({
        $_->{kind} eq 'alias'
    } @{$elixir->{entities}}),
    'Elixir alias recognized'
);

ok(
    !-e 'tests/prolog_should_not_execute',
    'Prolog directive was not executed'
);

ok(
    !-e 'tests/elixir_should_not_execute',
    'Elixir top-level code was not executed'
);

done_testing;
