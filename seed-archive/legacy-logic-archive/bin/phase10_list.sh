#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cat "$ROOT/research/phase10_ada_aerospace.tsv"
