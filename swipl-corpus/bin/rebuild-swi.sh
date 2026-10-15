#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT/builds/swi-7.2.0/src"

SOURCE_DATE_EPOCH=1432114319
export SOURCE_DATE_EPOCH

for pass in 1 2; do
  "$ROOT/bin/with-tools.sh" make clean \
    > "$ROOT/evidence/swi-rebuild-$pass-clean.log" 2>&1

  "$ROOT/bin/with-tools.sh" timeout 240 make -j2 \
    > "$ROOT/evidence/swi-rebuild-$pass.log" 2>&1

  sha256sum \
    swipl \
    swipl.prc \
    ../lib/x86_64-linux/libswipl.a \
    > "$ROOT/evidence/swi-rebuild-$pass.sha256"
done

cmp \
  "$ROOT/evidence/swi-rebuild-1.sha256" \
  "$ROOT/evidence/swi-rebuild-2.sha256"
