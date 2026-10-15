#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

{
  uname -a
  gcc --version
  make --version
  perl -v

  runtime/openssl102c/bin/openssl version -a

  runtime/otp18/bin/erl \
    +S 2:2 \
    +A 2 \
    -noshell \
    -eval '
      io:format(
        "~s~n",
        [erlang:system_info(system_version)]
      ),
      halt().
    '

  PATH="$ROOT/runtime/otp18/bin:$PATH" \
    ERL_FLAGS='+S 2:2 +A 2' \
    builds/elixir-1.0.5/bin/elixir --version
} > evidence/RUNTIME_VERSIONS.txt 2>&1

find runtime builds/elixir-1.0.5/lib \
  -type f \
  \( \
    -name '*.so*' \
    -o -name '*.beam' \
    -o -name 'openssl' \
    -o -name 'beam.smp' \
  \) \
  -exec sha256sum {} + \
  | LC_ALL=C sort \
  > evidence/RUNTIME_SHA256SUMS

ldd runtime/otp18/lib/crypto-*/priv/lib/crypto.so \
  > evidence/OTP18_CRYPTO_LINKAGE.txt
