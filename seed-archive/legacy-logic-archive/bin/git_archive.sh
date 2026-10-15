#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODE=${1:-list}
case "$MODE" in
 list) cat "$ROOT/research/repos.tsv" ;;
 fetch)
   [ "${2:-}" ] || { echo 'usage: bin/git_archive.sh fetch REPOSITORY_NAME' >&2; exit 2; }
   NAME=$2
   case "$NAME" in *[!a-zA-Z0-9._-]*|'') echo 'invalid name' >&2; exit 2;; esac
   LINE=$(awk -F '\t' -v name="$NAME" 'NR>1 && $2==name {print $3; exit}' "$ROOT/research/repos.tsv")
   [ -n "$LINE" ] || { echo 'repository not in curated list' >&2; exit 2; }
   mkdir -p "$ROOT/git" "$ROOT/metadata"
   if [ -d "$ROOT/git/$NAME.git" ]; then git -C "$ROOT/git/$NAME.git" fetch --prune origin; else git clone --mirror -- "$LINE" "$ROOT/git/$NAME.git"; fi
   REV=$(git -C "$ROOT/git/$NAME.git" rev-parse HEAD)
   DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
   printf '%s\t%s\t%s\t%s\n' "$NAME" "$LINE" "$REV" "$DATE" >> "$ROOT/metadata/git_revisions.tsv"
   echo "archived $NAME at $REV" ;;
 *) echo 'usage: bin/git_archive.sh list|fetch NAME' >&2; exit 2;;
esac
