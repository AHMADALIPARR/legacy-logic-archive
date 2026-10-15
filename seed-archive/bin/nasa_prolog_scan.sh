#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
# Read-only inspection of an already downloaded Git mirror.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

MIRROR=${1:-"$ROOT/git/NASA-Open-Source-Catalog.git"}

[ -d "$MIRROR" ] || {
  echo "Missing local mirror: $MIRROR" >&2
  exit 2
}

git -C "$MIRROR" rev-parse --verify HEAD >/dev/null

printf 'path\tclassification\n'

git -C "$MIRROR" ls-tree -r --name-only HEAD | awk '
  /\.(pl|pro|prolog)$/ {
    print $0 "\tprolog-candidate"
  }

  /(^|\/)(LICENSE|COPYING|NOTICE)(\.|$)/ {
    print $0 "\trights-review"
  }

  /(^|\/)(catalog|code-history|code)\.json$/ {
    print $0 "\tmetadata-catalog"
  }
'
