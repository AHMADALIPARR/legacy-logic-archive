# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

jq -r '
  select(.language=="Erlang")
  | [.id,.path,.source_sha256]
  | @tsv
' evidence/PHASE16_FAILURES.jsonl > evidence/erlang18-input.tsv

ERL_FLAGS='+S 2:2 +A 2'
export ERL_FLAGS

runtime/otp18/bin/erlc -o native native/recheck_erlang18.erl

runtime/otp18/bin/erl \
  -noshell \
  -pa native \
  -s recheck_erlang18 main \
  -extra evidence/erlang18-input.tsv evidence/erlang18-output.tsv

perl bin/convert-erlang18.pl
