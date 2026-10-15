#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

if test -e builds/otp-18.0; then
  echo 'Refusing to overwrite an existing OTP build tree' >&2
  exit 2
fi

mkdir -p builds/otp-18.0

cp -R \
  ../phase15/originals/otp-18.0/. \
  builds/otp-18.0/

cd builds/otp-18.0

"$ROOT/bin/with-tools.sh" sh ./otp_build autoconf

# Compatibility changes apply only to generated configure scripts.
perl -MFile::Find -e '
find({
  no_chdir => 1,
  wanted => sub {
    return unless -f $_ && m{/configure$};

    open my $f, q(<), $_ or die $!;
    local $/;
    my $b = <$f>;

    if ($b =~ s/then\n\s*\nelse/then\n  : # phase17 generated-configure compatibility no-op\nelse/g) {
      open my $w, q(>), $_ or die $!;
      print $w $b;
    }
  }
}, q(.));
'

ERL_TOP="$ROOT/builds/otp-18.0"
erl_top="$ERL_TOP"
ERL_FLAGS='+S 2:2 +A 2'

export ERL_TOP erl_top ERL_FLAGS

"$ROOT/bin/with-tools.sh" sh ./configure \
  --prefix="$ROOT/builds/otp18-install" \
  --with-ssl="$ROOT/runtime/openssl102c" \
  --enable-dynamic-ssl-lib \
  --with-ssl-rpath="$ROOT/runtime/openssl102c/lib" \
  --without-javac \
  --without-wx \
  --without-odbc \
  --disable-hipe \
  --without-termcap \
  CFLAGS='-O2 -fcommon -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion'

printf '%s\n' 'wx debugger observer reltool et' \
  > lib/SKIP-APPLICATIONS

"$ROOT/bin/with-tools.sh" make -j2

"$ROOT/bin/with-tools.sh" sh ./otp_build \
  release -a "$ROOT/runtime/otp18"

cd "$ROOT/runtime/otp18"

sh ./Install -minimal "$ROOT/runtime/otp18"
