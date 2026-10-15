#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT/builds/swi-7.2.0/src"

env -u SWI_HOME_DIR timeout 15 ./swipl.sh \
  -q \
  -f none \
  -s "$ROOT/originals/swi-bench/qsort.pl" \
  -g 'qsort([3,1,2,1],R,[]),(R==[1,1,2,3]->write(qsort_pass),nl,halt(0);halt(1))' \
  -t 'halt(1)' \
  > "$ROOT/evidence/swi72-qsort.log" 2>&1

printf '0\n' > "$ROOT/evidence/swi72-qsort.exit"

env -u SWI_HOME_DIR timeout 15 ./swipl.sh \
  -q \
  -f none \
  -s "$ROOT/originals/swi-bench/queens_8.pl" \
  -g 'findall(Q,queens(8,Q),Qs),length(Qs,N),(N=:=92->write(queens_92_pass),nl,halt(0);halt(1))' \
  -t 'halt(1)' \
  > "$ROOT/evidence/swi72-queens.log" 2>&1

printf '0\n' > "$ROOT/evidence/swi72-queens.exit"

cd "$ROOT"

bin/with-tools.sh erl -noshell -eval '
  code:unstick_mod(gb_sets),
  code:purge(gb_sets),
  {module,gb_sets} = code:load_abs("builds/examples/erlang/gb_sets"),
  S = gb_sets:from_list([3,1,2,1]),
  [1,2,3] = gb_sets:to_list(S),
  true = gb_sets:is_member(2,S),
  io:format("historical_gb_sets_pass~n"),
  halt().
' > evidence/erlang-example-run.log 2>&1

printf '0\n' > evidence/erlang-example-run.exit

bin/with-tools.sh elixir tests/run_historical_base.exs \
  > evidence/elixir-example.log 2>&1

printf '0\n' > evidence/elixir-example.exit

bin/with-tools.sh timeout 10 builds/examples/ada/derived_aggregate \
  > evidence/ada-example-run.log 2>&1

printf '0\n' > evidence/ada-example-run.exit
