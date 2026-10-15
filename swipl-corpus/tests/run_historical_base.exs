# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
# Executes only the reviewed pure Base encoding module
# in a disposable VM.

Code.compiler_options(ignore_module_conflict: true)

Code.compile_file(
  "../historical-corpus/originals/elixir-1.0.5/lib/elixir/lib/base.ex"
)

"Zm9v" = Base.encode64("foo")
"foo" = Base.decode64!("Zm9v")
"666F6F" = Base.encode16("foo")

IO.puts("historical_base_pass")
