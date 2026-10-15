# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

test "$(cat evidence/phase17-verification.exit)" = 0

find . \
  -type f \
  ! -path './builds/*' \
  ! -path './normalized/prolog-parts/*' \
  ! -path './evidence/prolog-inputs/*' \
  ! -name PACKAGE_SHA256SUMS \
  -exec sha256sum {} + \
  | LC_ALL=C sort \
  > PACKAGE_SHA256SUMS

find builds/elixir-1.0.5 \
  -type f \
  -exec sha256sum {} + \
  | LC_ALL=C sort \
  >> PACKAGE_SHA256SUMS

cd "$ROOT/.."

tar \
  --sort=name \
  --mtime='2026-10-15 00:00:00Z' \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --exclude='phase17/builds/openssl*' \
  --exclude='phase17/builds/otp*' \
  --exclude='phase17/normalized/prolog-parts' \
  --exclude='phase17/evidence/prolog-inputs' \
  -cf - phase17 \
  | gzip -n \
  > legacy-logic-archive-phase17.tar.gz

sha256sum legacy-logic-archive-phase17.tar.gz \
  > legacy-logic-archive-phase17.tar.gz.sha256

gzip -t legacy-logic-archive-phase17.tar.gz

sha256sum -c legacy-logic-archive-phase17.tar.gz.sha256
