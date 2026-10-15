#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

perl bin/prepare-parser-inputs.pl
perl bin/profile-operators.pl

bin/with-tools.sh swipl \
  -q \
  -f native/operator_registry.pl \
  -- \
  evidence/parser-input-Prolog.jsonl \
  evidence/EXPORTED_OPERATOR_REGISTRY.jsonl

perl bin/recheck-prolog-isolated.pl

sh bin/recheck-erlang18.sh
sh bin/recheck-elixir105.sh

perl bin/recheck-ada.pl

sh tests/prolog-fixtures.sh

perl bin/classify-parsers.pl
