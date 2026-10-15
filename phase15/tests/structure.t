# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../bin";
use structure;

my @cases = (
    [
        'Erlang',
        "%% fake() -> bad.\n-module(example).\n-include(\"x.hrl\").\nf(X) -> X.\n",
        ['example', 'f'],
        'x.hrl',
    ],
    [
        'Elixir',
        "# def wrong\ndefmodule Sample do\n  import Enum\n  def answer(), do: 42\nend\n",
        ['Sample', 'answer'],
        'Enum',
    ],
    [
        'Prolog',
        "% fake(x).\n:- use_module(library(lists)).\nmember(X, [X|_]).\n",
        ['member'],
        'library(lists)',
    ],
    [
        'Ada',
        "-- procedure Wrong;\nwith Ada.Text_IO;\nprocedure Hello is\n",
        ['Hello'],
        'Ada.Text_IO',
    ],
    [
        'Pascal',
        "program demo;\nuses system;\nprocedure run;\n",
        ['demo', 'run'],
        'system',
    ],
    [
        'C',
        "#include <stdio.h>\nint f(void) { return 1; }\n",
        ['f'],
        'stdio.h',
    ],
);

for my $case (@cases) {
    my ($language, $source, $names, $dependency) = @$case;

    my ($entities, $dependencies) =
        Structure::extract($language, $source);

    is_deeply(
        [map { $_->{name} } @$entities],
        $names,
        "$language supported declaration extraction"
    );

    is(
        $dependencies->[0]{reference},
        $dependency,
        "$language literal dependency extraction"
    );
}

done_testing;
