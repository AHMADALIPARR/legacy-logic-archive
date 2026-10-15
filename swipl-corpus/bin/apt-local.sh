#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

APT_CONFIG="$ROOT/apt/apt.conf" exec /usr/bin/apt-get \
  -o Dir::Etc::main=- \
  -o Dir::Etc::parts=- \
  -o Dir::Etc::sourcelist="$ROOT/apt/sources.list" \
  -o Dir::Etc::sourceparts=- \
  -o Dir::State::lists="$ROOT/apt/lists" \
  -o Dir::Cache="$ROOT/apt/cache" \
  -o Dir::Cache::archives="$ROOT/toolchain/debs" \
  -o Debug::NoLocking=1 \
  -o APT::Sandbox::User=agent \
  "$@"
