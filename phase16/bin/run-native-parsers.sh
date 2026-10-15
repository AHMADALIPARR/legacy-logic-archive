# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

perl bin/parser-inputs.pl

bin/with-tools.sh erlc \
  -o native native/parse_erlang.erl

bin/with-tools.sh swipl \
  -q \
  -f none \
  -s native/parse_prolog.pl \
  -- \
  evidence/parser-input-Prolog.jsonl \
  normalized/NATIVE_PROLOG.jsonl

bin/with-tools.sh elixir \
  native/parse_elixir.exs \
  evidence/parser-input-Elixir.jsonl \
  normalized/NATIVE_ELIXIR.jsonl

bin/with-tools.sh erl \
  -noshell \
  -pa native \
  -s parse_erlang main \
  -extra \
  evidence/parser-input-Erlang.jsonl \
  normalized/NATIVE_ERLANG.jsonl

perl bin/check-ada.pl
perl bin/attach-native.pl
