#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cat "$ROOT/sources/phase9_ads_cryogenics.tsv"
