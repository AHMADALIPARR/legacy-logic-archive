#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

perl bin/check-debian-index.pl
perl bin/toolchain-lock.pl

mkdir -p toolchain/root

for deb in toolchain/debs/*.deb; do
  dpkg-deb -x "$deb" toolchain/root
done

sh bin/relocate-autoconf.sh

bin/with-tools.sh swipl --version

bin/with-tools.sh erl -noshell -eval '
  io:format(
    "OTP ~s~n",
    [erlang:system_info(otp_release)]
  ),
  halt().
'

bin/with-tools.sh elixir --version
bin/with-tools.sh gnatmake --version
