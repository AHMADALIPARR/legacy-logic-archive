# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
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
  > /tmp/phase16-package-paths

find . \
  -maxdepth 1 \
  -type f \
  -print0 \
  >> /tmp/phase16-package-paths

printf '%s\0' \
  normalized/STRUCTURE.jsonl \
  normalized/VERIFICATION_OVERLAY.jsonl \
  normalized/NATIVE_PROLOG.jsonl \
  normalized/NATIVE_ERLANG.jsonl \
  normalized/NATIVE_ELIXIR.jsonl \
  normalized/NATIVE_ADA.jsonl \
  >> /tmp/phase16-package-paths

LC_ALL=C sort -z /tmp/phase16-package-paths \
  | xargs -0 sha256sum \
  > evidence/DELIVERY_SHA256SUMS

cd "$(dirname -- "$ROOT")"

tar \
  --sort=name \
  --mtime=2026-10-15T00:00:00Z \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --exclude=phase16/builds/otp-18.0 \
  --exclude=phase16/toolchain/root \
  --exclude=phase16/apt/gnupg \
  --exclude=phase16/erl_crash.dump \
  -cf legacy-logic-archive-phase16.tar \
  phase16

gzip -1 -n legacy-logic-archive-phase16.tar
gzip -t legacy-logic-archive-phase16.tar.gz

sha256sum legacy-logic-archive-phase16.tar.gz \
  > legacy-logic-archive-phase16.tar.gz.sha256
