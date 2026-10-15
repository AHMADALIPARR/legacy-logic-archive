#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

find \
  bin native tests reports evidence apt toolchain/debs \
  downloads training-export \
  -type f \
  ! -name DELIVERY_SHA256SUMS \
  ! -path 'apt/gnupg/*' \
  -print0 \
  > /tmp/swipl-corpus-package-paths

find . \
  -maxdepth 1 \
  -type f \
  -print0 \
  >> /tmp/swipl-corpus-package-paths

printf '%s\0' \
  normalized/STRUCTURE.jsonl \
  normalized/VERIFICATION_OVERLAY.jsonl \
  normalized/NATIVE_PROLOG.jsonl \
  normalized/NATIVE_ERLANG.jsonl \
  normalized/NATIVE_ELIXIR.jsonl \
  normalized/NATIVE_ADA.jsonl \
  >> /tmp/swipl-corpus-package-paths

LC_ALL=C sort -z /tmp/swipl-corpus-package-paths \
  | xargs -0 sha256sum \
  > evidence/DELIVERY_SHA256SUMS

cd "$(dirname -- "$ROOT")"

tar \
  --sort=name \
  --mtime=2026-10-15T00:00:00Z \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --exclude=swipl-corpus/builds/otp-18.0 \
  --exclude=swipl-corpus/toolchain/root \
  --exclude=swipl-corpus/apt/gnupg \
  --exclude=swipl-corpus/erl_crash.dump \
  -cf legacy-logic-archive-swipl-corpus.tar \
  swipl-corpus

gzip -1 -n legacy-logic-archive-swipl-corpus.tar
gzip -t legacy-logic-archive-swipl-corpus.tar.gz

sha256sum legacy-logic-archive-swipl-corpus.tar.gz \
  > legacy-logic-archive-swipl-corpus.tar.gz.sha256
