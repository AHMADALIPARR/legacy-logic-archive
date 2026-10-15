#!/bin/sh
# Permission-aware source collector. Never executes downloaded material.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
QUEUE=${1:-"$ROOT/sources/approved.tsv"}
[ -f "$QUEUE" ] || { echo "missing queue: $QUEUE" >&2; exit 2; }
mkdir -p "$ROOT/tmp" "$ROOT/metadata" "$ROOT/objects/sha256"
TAB=$(printf '\t')
while IFS="$TAB" read -r language url rights approval note; do
  case "$language" in ''|'#'*) continue;; esac
  if [ "$approval" != approved ]; then printf 'SKIP unapproved %s\n' "$url"; continue; fi
  case "$rights" in BSD-2-Clause|MIT|Apache-2.0|GPL-2.0|GPL-3.0|LGPL-2.1|LGPL-3.0|CC0-1.0|public-domain) :;; *) printf 'SKIP rights-review %s\n' "$url"; continue;; esac
  case "$url" in https://*) :;; *) printf 'SKIP non-HTTPS %s\n' "$url"; continue;; esac
  case "$url" in *'`'*|*'$('*|*' '*|*'\r'*) printf 'SKIP invalid-url\n'; continue;; esac
  temp=$(mktemp "$ROOT/tmp/download.XXXXXXXX")
  if curl --fail --location --proto '=https' --proto-redir '=https' --max-redirs 3 --connect-timeout 12 --max-time 90 --retry 2 --max-filesize 25000000 --silent --show-error --output "$temp" "$url"; then
    size=$(wc -c < "$temp" | tr -d ' ')
    if [ "$size" -gt 25000000 ]; then printf 'SKIP oversized %s\n' "$url"; rm -f "$temp"; continue; fi
    hash=$(sha256sum "$temp" | cut -d ' ' -f 1)
    dir="$ROOT/objects/sha256/$(printf %.2s "$hash")"
    mkdir -p "$dir"
    if [ ! -e "$dir/$hash" ]; then mv "$temp" "$dir/$hash"; chmod 444 "$dir/$hash"; else rm -f "$temp"; fi
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    # TSV metadata, reject embedded tab/newline in untrusted values before adding new sources.
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$hash" "$language" "$url" "$size" "$timestamp" "$rights" "$note" >> "$ROOT/metadata/manifest.tsv"
    printf 'OK %s %s bytes=%s\n' "$language" "$hash" "$size"
  else printf 'FAILED %s\n' "$url" >&2; rm -f "$temp"; fi
done < "$QUEUE"
