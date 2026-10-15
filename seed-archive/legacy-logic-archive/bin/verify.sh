#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
find "$ROOT/objects/sha256" -type f | while IFS= read -r file; do
  expected=${file##*/}
  actual=$(sha256sum "$file" | cut -d ' ' -f 1)
  [ "$expected" = "$actual" ] || { echo "CORRUPT $file" >&2; exit 1; }
done
printf 'All stored object hashes verified\n'
