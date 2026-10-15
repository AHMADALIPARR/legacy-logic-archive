#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

[ "$#" -eq 3 ] || {
  echo 'usage: ingest.sh LANGUAGE SOURCE_URL LOCAL_FILE' >&2
  exit 2
}

LANGUAGE=$1
URL=$2
FILE=$3

[ -f "$FILE" ] || exit 2

HASH=$(sha256sum "$FILE" | cut -d ' ' -f 1)
DIR="$ROOT/objects/sha256/$(printf %.2s "$HASH")"

mkdir -p "$DIR"

cp -n "$FILE" "$DIR/$HASH"

SIZE=$(wc -c < "$FILE" | tr -d ' ')
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$HASH" \
  "$LANGUAGE" \
  "$URL" \
  "$SIZE" \
  "$DATE" \
  unreviewed \
  unknown \
  >> "$ROOT/metadata/manifest.tsv"

printf 'archived sha256:%s\n' "$HASH"
