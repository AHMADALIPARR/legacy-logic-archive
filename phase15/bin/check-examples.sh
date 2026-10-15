# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

mkdir -p builds/examples evidence

cc --version > evidence/compiler-version.txt
uname -srm > evidence/build-platform.txt

: > evidence/example-results.tsv

for name in 20000112-1 20000113-1; do
  source="originals/gnat-4.2.0/gcc/testsuite/gcc.c-torture/execute/$name.c"

  for pass in 1 2; do
    cc \
      -std=gnu89 \
      -w \
      -O2 \
      -fno-ident \
      -Wl,--build-id=none \
      "$source" \
      -o "builds/examples/$name" \
      > "evidence/$name-build-$pass.log" 2>&1

    sha256sum "builds/examples/$name" \
      > "evidence/$name-binary-$pass.sha256"

    timeout 5 "builds/examples/$name"
  done

  cmp \
    "evidence/$name-binary-1.sha256" \
    "evidence/$name-binary-2.sha256"

  printf '%s\tPASS\tPASS\t%s\n' \
    "gnat-4.2.0:gcc/testsuite/gcc.c-torture/execute/$name.c" \
    "$(cut -d ' ' -f 1 "evidence/$name-binary-1.sha256")" \
    >> evidence/example-results.tsv
done
