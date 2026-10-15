#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

perl bin/assemble-swi.pl builds/swi-7.2.0

cd builds/swi-7.2.0/src

"$ROOT/bin/with-tools.sh" autoheader
"$ROOT/bin/with-tools.sh" autoconf

"$ROOT/bin/with-tools.sh" sh ./configure \
  --without-gmp \
  --without-readline \
  --disable-shared \
  --prefix="$ROOT/builds/swi-install" \
  CFLAGS='-O2 -fcommon -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion'

# Correct only the generated object-output rule.
perl -i -pe \
  's/(\$\(CC\) -c .*?)\s+\$<\s*$/$1 \$< -o \$\@\n/' \
  Makefile

SOURCE_DATE_EPOCH=1432114319
export SOURCE_DATE_EPOCH

"$ROOT/bin/with-tools.sh" make -j2
