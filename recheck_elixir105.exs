# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
[input, output] = System.argv()

File.mkdir_p!("normalized/elixir105")

{:ok, out} = File.open(output, [:write])

File.stream!(input)
|> Enum.with_index()
|> Enum.each(fn {line, index} ->
  [id, path, hash] =
    line
    |> String.strip()
    |> String.split("\t")

  result =
    try do
      Code.string_to_quoted(File.read!(path))
    rescue
      error ->
        {:parser_exception, Exception.message(error)}
    end

  status =
    case result do
      {:ok, _} ->
        "parsed"

      {:error, _} ->
        "parse_errors"

      _ ->
        "parser_exception"
    end

  artifact =
    "normalized/elixir105/"
    <> Integer.to_string(index)
    <> ".etf"

  File.write!(
    artifact,
    :erlang.term_to_binary(result)
  )

  IO.binwrite(
    out,
    Enum.join(
      [id, path, hash, status, artifact],
      "\t"
    ) <> "\n"
  )
end)

File.close(out)
