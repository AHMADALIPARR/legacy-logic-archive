# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

PHASE16_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export PHASE16_ROOT

PATH="$PHASE16_ROOT/bin/native:$PHASE16_ROOT/toolchain/root/usr/bin:$PATH"

LD_LIBRARY_PATH="$PHASE16_ROOT/toolchain/root/usr/lib/x86_64-linux-gnu:$PHASE16_ROOT/toolchain/root/usr/lib/swi-prolog/lib/x86_64-linux${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

autom4te_perllibdir="$PHASE16_ROOT/toolchain/root/usr/share/autoconf"
AC_MACRODIR="$autom4te_perllibdir"
AUTOM4TE="$PHASE16_ROOT/toolchain/root/usr/bin/autom4te"
M4="$PHASE16_ROOT/toolchain/root/usr/bin/m4"

export PATH LD_LIBRARY_PATH
export autom4te_perllibdir AC_MACRODIR AUTOM4TE M4

export AUTOM4TE_CFG="$PHASE16_ROOT/toolchain/config/autom4te.cfg"

export trailer_m4="$PHASE16_ROOT/toolchain/root/usr/share/autoconf/autoconf/trailer.m4"

export SWI_HOME_DIR="$PHASE16_ROOT/toolchain/root/usr/lib/swi-prolog"

export ADA_INCLUDE_PATH="$PHASE16_ROOT/toolchain/root/usr/lib/gcc/x86_64-linux-gnu/14/adainclude"

export ADA_OBJECTS_PATH="$PHASE16_ROOT/toolchain/root/usr/lib/gcc/x86_64-linux-gnu/14/adalib"

export COMPILER_PATH="$PHASE16_ROOT/toolchain/root/usr/libexec/gcc/x86_64-linux-gnu/14:/usr/lib/gcc/x86_64-linux-gnu/14:/usr/libexec/gcc/x86_64-linux-gnu/14"

export LIBRARY_PATH="$PHASE16_ROOT/toolchain/root/usr/lib/x86_64-linux-gnu:$PHASE16_ROOT/toolchain/root/usr/lib/gcc/x86_64-linux-gnu/14/adalib${LIBRARY_PATH:+:$LIBRARY_PATH}"

exec "$@"
