# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
defmodule Fixture do
  alias Enum, as: E

  defmacro identity(x), do: x

  def value(x) when is_integer(x) do
    {:ok, x}
  end
end

File.write!("tests/elixir_should_not_execute", "incorrect")
