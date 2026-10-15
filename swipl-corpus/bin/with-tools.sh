#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

SWIPL_CORPUS_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export SWIPL_CORPUS_ROOT

PATH="$SWIPL_CORPUS_ROOT/bin/native:$SWIPL_CORPUS_ROOT/toolchain/root/usr/bin:$PATH"

LD_LIBRARY_PATH="$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/x86_64-linux-gnu:$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/swi-prolog/lib/x86_64-linux${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

autom4te_perllibdir="$SWIPL_CORPUS_ROOT/toolchain/root/usr/share/autoconf"
AC_MACRODIR="$autom4te_perllibdir"
AUTOM4TE="$SWIPL_CORPUS_ROOT/toolchain/root/usr/bin/autom4te"
M4="$SWIPL_CORPUS_ROOT/toolchain/root/usr/bin/m4"

export PATH LD_LIBRARY_PATH
export autom4te_perllibdir AC_MACRODIR AUTOM4TE M4

export AUTOM4TE_CFG="$SWIPL_CORPUS_ROOT/toolchain/config/autom4te.cfg"

export trailer_m4="$SWIPL_CORPUS_ROOT/toolchain/root/usr/share/autoconf/autoconf/trailer.m4"

export SWI_HOME_DIR="$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/swi-prolog"

export ADA_INCLUDE_PATH="$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/gcc/x86_64-linux-gnu/14/adainclude"

export ADA_OBJECTS_PATH="$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/gcc/x86_64-linux-gnu/14/adalib"

export COMPILER_PATH="$SWIPL_CORPUS_ROOT/toolchain/root/usr/libexec/gcc/x86_64-linux-gnu/14:/usr/lib/gcc/x86_64-linux-gnu/14:/usr/libexec/gcc/x86_64-linux-gnu/14"

export LIBRARY_PATH="$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/x86_64-linux-gnu:$SWIPL_CORPUS_ROOT/toolchain/root/usr/lib/gcc/x86_64-linux-gnu/14/adalib${LIBRARY_PATH:+:$LIBRARY_PATH}"

exec "$@"
