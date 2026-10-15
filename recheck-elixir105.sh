# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

jq -r '
  select(.language=="Elixir")
  | [.id,.path,.source_sha256]
  | @tsv
' evidence/PHASE16_FAILURES.jsonl > evidence/elixir105-input.tsv

PATH="$ROOT/runtime/otp18/bin:$PATH"
ERL_FLAGS='+S 2:2 +A 2'
ELIXIR_ERL_OPTIONS='+S 2:2 +A 2'

export PATH ERL_FLAGS ELIXIR_ERL_OPTIONS

builds/elixir-1.0.5/bin/elixir \
  native/recheck_elixir105.exs \
  evidence/elixir105-input.tsv \
  evidence/elixir105-output.tsv

perl bin/convert-elixir105.pl
