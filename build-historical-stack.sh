# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

test "$(cat evidence/openssl-test-historical-time.exit)" = 0
test "$(cat evidence/openssl-install.exit)" = 0

sh bin/build-otp18.sh \
  > evidence/otp18-build.log 2>&1

printf '0\n' > evidence/otp18-build.exit

runtime/otp18/bin/erl \
  +S 2:2 \
  +A 2 \
  -noshell \
  -eval '
    "18" = erlang:system_info(otp_release),
    ok = application:start(crypto),
    <<186,120,22,191,143,1,207,234,
      65,65,64,222,93,174,34,35,
      176,3,97,163,150,23,122,156,
      180,16,255,97,242,0,21,173>>
      = crypto:hash(sha256, <<"abc">>),
    io:format(
      "OTP18 crypto SHA256 pass ~p~n",
      [crypto:info_lib()]
    ),
    halt().
  ' > evidence/otp18-crypto-check.log 2>&1

printf '0\n' > evidence/otp18-crypto-check.exit

mkdir -p builds/elixir-1.0.5

cp -R \
  ../phase15/originals/elixir-1.0.5/. \
  builds/elixir-1.0.5/

cd builds/elixir-1.0.5

PATH="$ROOT/runtime/otp18/bin:$PATH"
ERL_FLAGS='+S 2:2 +A 2'
ELIXIR_ERL_OPTIONS='+S 2:2 +A 2'

export PATH ERL_FLAGS ELIXIR_ERL_OPTIONS

make compile \
  > "$ROOT/evidence/elixir105-make.log" 2>&1

printf '0\n' > "$ROOT/evidence/elixir105-make.exit"

bin/elixir --version \
  > "$ROOT/evidence/elixir105-version.log" 2>&1

bin/elixir -e '
  "Zm9v" = Base.encode64("foo")
  "foo" = Base.decode64!("Zm9v")

  task = Task.async(fn ->
    Enum.sum(1..100)
  end)

  5050 = Task.await(task)

  <<186,120,22,191,143,1,207,234,
    65,65,64,222,93,174,34,35,
    176,3,97,163,150,23,122,156,
    180,16,255,97,242,0,21,173>>
    = :crypto.hash(:sha256, "abc")

  IO.puts("historical_elixir105_base_task_crypto_pass")
' > "$ROOT/evidence/elixir105-runtime-check.log" 2>&1

printf '0\n' \
  > "$ROOT/evidence/elixir105-runtime-check.exit"
