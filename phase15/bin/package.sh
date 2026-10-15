# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PARENT=$(dirname -- "$ROOT")

cd "$ROOT"

find bin evidence reports \
  -type f \
  ! -name DELIVERY_SHA256SUMS \
  -print0 \
  > /tmp/phase15-checksum-paths

find . \
  -maxdepth 1 \
  -type f \
  -print0 \
  >> /tmp/phase15-checksum-paths

printf '%s\0' \
  normalized/STRUCTURE.jsonl \
  training-export/ALLOWLIST.jsonl \
  >> /tmp/phase15-checksum-paths

LC_ALL=C sort -z /tmp/phase15-checksum-paths \
  | xargs -0 sha256sum \
  > evidence/DELIVERY_SHA256SUMS

cd "$PARENT"

tar \
  --sort=name \
  --mtime=2026-10-15T00:00:00Z \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --exclude=phase15/builds/swi \
  -cf legacy-logic-archive-phase15.tar \
  phase14 phase15

gzip -1 -n legacy-logic-archive-phase15.tar
gzip -t legacy-logic-archive-phase15.tar.gz

sha256sum legacy-logic-archive-phase15.tar.gz \
  > legacy-logic-archive-phase15.tar.gz.sha256
