# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

for label in valid invalid isolation; do
  path="tests/prolog-$label.pl"
  hash=$(sha256sum "$path" | cut -d ' ' -f1)

  jq -nc \
    --arg id "$label" \
    --arg path "$path" \
    --arg sha256 "$hash" \
    '{id:$id,path:$path,sha256:$sha256}' \
    > "tests/$label-input.jsonl"

  bin/with-tools.sh swipl \
    -q \
    -f native/parse_prolog.pl \
    -- \
    "tests/$label-input.jsonl" \
    "tests/$label-output.jsonl"
done

jq -e '
  .status=="parsed"
  and .term_count==4
  and .source_execution==false
  and (
    [.terms[].entity.kind]
    | index("dcg_rule")!=null
  )
' tests/valid-output.jsonl

jq -e '.status=="parse_errors"' \
  tests/invalid-output.jsonl

jq -e '.status=="parse_errors"' \
  tests/isolation-output.jsonl
