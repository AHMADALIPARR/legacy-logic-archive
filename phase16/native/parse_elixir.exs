# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
defmodule Phase16 do
  def json(value) when is_binary(value) do
    "\"" <> escape(value) <> "\""
  end

  def json(value) when is_integer(value) do
    Integer.to_string(value)
  end

  def json(value) when is_float(value) do
    Float.to_string(value)
  end

  def json(true), do: "true"
  def json(false), do: "false"
  def json(nil), do: "null"

  def json(value) when is_atom(value) do
    json(Atom.to_string(value))
  end

  def json(value) when is_list(value) do
    "[" <> Enum.map_join(value, ",", &json/1) <> "]"
  end

  def json(value) when is_tuple(value) do
    json(%{"tuple" => Tuple.to_list(value)})
  end

  def json(value) when is_map(value) do
    body =
      value
      |> Enum.sort_by(fn {key, _} -> to_string(key) end)
      |> Enum.map_join(",", fn {key, item} ->
        json(to_string(key)) <> ":" <> json(item)
      end)

    "{" <> body <> "}"
  end

  def escape(string) do
    string
    |> String.to_charlist()
    |> Enum.map_join(fn character ->
      case character do
        34 ->
          "\\\""

        92 ->
          "\\\\"

        10 ->
          "\\n"

        13 ->
          "\\r"

        9 ->
          "\\t"

        value when value < 32 ->
          "\\u" <>
            (Integer.to_string(value, 16)
             |> String.pad_leading(4, "0"))

        value ->
          <<value::utf8>>
      end
    end)
  end

  def run(input, output) do
    File.mkdir_p!("normalized/native/elixir")

    File.open!(output, [:write], fn out ->
      File.stream!(input)
      |> Enum.each(fn line ->
        record = :json.decode(line)
        source = File.read!(record["path"])

        result =
          try do
            {parse_result, diagnostics} =
              Code.with_diagnostics([log: false], fn ->
                Code.string_to_quoted(
                  source,
                  columns: true,
                  token_metadata: true,
                  file: record["path"]
                )
              end)

            result =
              case parse_result do
                {:ok, ast} ->
                  {_, entities} =
                    Macro.prewalk(ast, [], fn node, accumulator ->
                      {node, entity(node, accumulator)}
                    end)

                  binary =
                    :erlang.term_to_binary(ast, [:deterministic])

                  hash =
                    Base.encode16(
                      :crypto.hash(:sha256, binary),
                      case: :lower
                    )

                  path =
                    "normalized/native/elixir/" <> hash <> ".etf"

                  File.write!(path, binary)

                  %{
                    status: "parsed",
                    ast_path: path,
                    ast_sha256: hash,
                    entities: Enum.reverse(entities)
                  }

                {:error, error} ->
                  %{
                    status: "parse_errors",
                    errors: [inspect(error, limit: :infinity)]
                  }
              end

            Map.put(
              result,
              :diagnostics,
              Enum.map(diagnostics, fn diagnostic ->
                inspect(diagnostic, limit: :infinity)
              end)
            )
          rescue
            error ->
              %{
                status: "parser_exception",
                errors: [Exception.message(error)]
              }
          end

        result =
          Map.merge(result, %{
            id: record["id"],
            source_sha256: record["sha256"],
            path: record["path"],
            language: "Elixir",
            parser: System.version(),
            source_execution: false
          })

        IO.write(out, json(result) <> "\n")
      end)
    end)
  end

  def entity({kind, metadata, arguments}, accumulator)
      when kind in [
             :defmodule,
             :defprotocol,
             :defimpl,
             :def,
             :defp,
             :defmacro,
             :defmacrop,
             :alias,
             :import,
             :require,
             :use
           ] and is_list(arguments) and is_list(metadata) do
    case arguments do
      [head | _] ->
        [
          %{
            kind: kind,
            name: Macro.to_string(head),
            line: Keyword.get(metadata, :line, 0)
          }
          | accumulator
        ]

      _ ->
        accumulator
    end
  end

  def entity(_, accumulator), do: accumulator
end

[input, output] = System.argv()
Phase16.run(input, output)
