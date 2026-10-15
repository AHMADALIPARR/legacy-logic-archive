#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
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
  --exclude='native-recheck/builds/openssl*' \
  --exclude='native-recheck/builds/otp*' \
  --exclude='native-recheck/normalized/prolog-parts' \
  --exclude='native-recheck/evidence/prolog-inputs' \
  -cf - native-recheck \
  | gzip -n \
  > legacy-logic-archive-native-recheck.tar.gz

sha256sum legacy-logic-archive-native-recheck.tar.gz \
  > legacy-logic-archive-native-recheck.tar.gz.sha256

gzip -t legacy-logic-archive-native-recheck.tar.gz

sha256sum -c legacy-logic-archive-native-recheck.tar.gz.sha256
