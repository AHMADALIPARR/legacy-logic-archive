#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CATALOG="$ROOT/sources/phase13_repos.tsv"
MIRRORS="$ROOT/data/git-mirrors"
SNAPSHOTS="$ROOT/data/snapshots"
META="$ROOT/metadata/phase13_ingestion.tsv"
mkdir -p "$MIRRORS" "$SNAPSHOTS" "$ROOT/metadata"
[ -f "$META" ] || printf 'id\tlanguage\tcommit\tfiles\tbytes\tsnapshot_sha256\trights_status\turl\n' > "$META"
case "${1:-}" in
  list) cat "$CATALOG"; exit 0;;
  fetch) [ $# -eq 2 ] || { echo 'usage: ingest_phase13.sh fetch REPO_ID' >&2; exit 2; };;
  *) echo 'usage: ingest_phase13.sh list | fetch REPO_ID' >&2; exit 2;;
esac
id=$2
row=$(awk -F '\t' -v id="$id" 'NR>1 && $1==id {print; exit}' "$CATALOG")
[ -n "$row" ] || { echo "Unknown repo: $id" >&2; exit 2; }
lang=$(printf '%s\n' "$row" | cut -f2)
url=$(printf '%s\n' "$row" | cut -f3)
rights=$(printf '%s\n' "$row" | cut -f4)
mirror="$MIRRORS/$id.git"
if [ -d "$mirror" ]; then git -C "$mirror" remote update --prune; else git clone --mirror "$url" "$mirror"; fi
commit=$(git --git-dir="$mirror" rev-parse HEAD)
archive="$SNAPSHOTS/$id-$commit.tar"
if [ ! -f "$archive" ]; then git --git-dir="$mirror" archive --format=tar --output="$archive" "$commit"; fi
sha=$(sha256sum "$archive" | cut -d' ' -f1)
files=$(git --git-dir="$mirror" ls-tree -r --name-only "$commit" | wc -l | tr -d ' ')
bytes=$(wc -c < "$archive" | tr -d ' ')
if ! grep -Fq "$(printf '\t%s\t' "$commit")" "$META"; then
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$lang" "$commit" "$files" "$bytes" "$sha" "$rights" "$url" >> "$META"
fi
printf 'Archived %s commit=%s files=%s bytes=%s sha256=%s\n' "$id" "$commit" "$files" "$bytes" "$sha"
