# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

mkdir -p "$ROOT/toolchain/config"

sed \
  "s|/usr/share/autoconf|$ROOT/toolchain/root/usr/share/autoconf|g" \
  "$ROOT/toolchain/root/usr/share/autoconf/autom4te.cfg" \
  > "$ROOT/toolchain/config/autom4te.cfg"
