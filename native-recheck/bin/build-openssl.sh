#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

if test -e builds/openssl-1.0.2c; then
  echo 'Refusing existing build tree' >&2
  exit 2
fi

mkdir -p builds/openssl-1.0.2c

cp -R \
  originals/openssl-1.0.2c/. \
  builds/openssl-1.0.2c/

cd builds/openssl-1.0.2c

SOURCE_DATE_EPOCH=1434067200
export SOURCE_DATE_EPOCH

sh ./config \
  shared \
  no-asm \
  -fPIC \
  -fno-common \
  -Wno-error=implicit-function-declaration \
  -Wno-error=incompatible-pointer-types \
  -Wno-error=int-conversion \
  --prefix="$ROOT/runtime/openssl102c" \
  --openssldir="$ROOT/runtime/openssl102c/ssl" \
  > "$ROOT/evidence/openssl-configure.log" 2>&1

make depend \
  > "$ROOT/evidence/openssl-depend.log" 2>&1

make -j1 \
  > "$ROOT/evidence/openssl-make.log" 2>&1

printf '0\n' > "$ROOT/evidence/openssl-make.exit"

set +e

make test \
  > "$ROOT/evidence/openssl-test.log" 2>&1

printf '%s\n' "$?" \
  > "$ROOT/evidence/openssl-test.exit"

set -e

patch -p0 < "$ROOT/patches/openssl-cms-historical-time.patch"

make test \
  > "$ROOT/evidence/openssl-test-historical-time.log" 2>&1

printf '0\n' \
  > "$ROOT/evidence/openssl-test-historical-time.exit"

make install_sw \
  > "$ROOT/evidence/openssl-install.log" 2>&1

printf '0\n' > "$ROOT/evidence/openssl-install.exit"
