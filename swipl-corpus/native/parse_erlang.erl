% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
-module(parse_erlang).
-export([main/0]).

main() ->
    [Input, Output] = init:get_plain_arguments(),

    {ok, In} = file:open(Input, [read, binary]),
    {ok, Out} = file:open(Output, [write, binary]),

    filelib:ensure_dir("normalized/native/erlang/placeholder"),

    loop(In, Out),

    file:close(In),
    file:close(Out),
    halt().

loop(In, Out) ->
    case file:read_line(In) of
        eof ->
            ok;

        {ok, Line} ->
            R = json:decode(Line),

            Path = unicode:characters_to_list(
                maps:get(<<"path">>, R)
            ),

            Result =
                try
                    parse_one(Path)
                catch
                    C:E ->
                        #{
                            status => parser_exception,
                            errors => [
                                unicode:characters_to_binary(
                                    io_lib:format("~tp:~tp", [C, E])
                                )
                            ]
                        }
                end,

            Record = maps:merge(
                Result,
                #{
                    id => maps:get(<<"id">>, R),
                    source_sha256 => maps:get(<<"sha256">>, R),
                    path => maps:get(<<"path">>, R),
                    language => <<"Erlang">>,
                    parser => unicode:characters_to_binary(
                        erlang:system_info(otp_release)
                    ),
                    source_execution => false,
                    scope =>
                        <<"epp_dodger syntax trees, preserving macros; no include expansion or execution">>
                }
            ),

            ok = file:write(
                Out,
                [json:encode(json_safe(Record)), "\n"]
            ),

            loop(In, Out)
    end.

parse_one(Path) ->
    case epp_dodger:parse_file(Path, [{no_fail, false}]) of
        {ok, Forms} ->
            Errors = [
                unicode:characters_to_binary(
                    io_lib:format(
                        "~tp",
                        [erl_syntax:error_marker_info(F)]
                    )
                )
                || F <- Forms,
                   erl_syntax:type(F) =:= error_marker
            ],

            Binary = term_to_binary(Forms, [deterministic]),

            Hash = binary:encode_hex(
                crypto:hash(sha256, Binary),
                lowercase
            ),

            AstPath =
                <<"normalized/native/erlang/", Hash/binary, ".etf">>,

            ok = file:write_file(AstPath, Binary),

            #{
                status =>
                    case Errors of
                        [] -> parsed;
                        _ -> parse_errors
                    end,
                ast_path => AstPath,
                ast_sha256 => Hash,
                errors => Errors,
                entities => lists:flatmap(fun safe_entity/1, Forms)
            };

        Other ->
            #{
                status => parse_errors,
                errors => [
                    unicode:characters_to_binary(
                        io_lib:format("~tp", [Other])
                    )
                ]
            }
    end.

safe_entity(Form) ->
    try
        entity(erl_syntax:type(Form), Form)
    catch
        _:_ -> []
    end.

entity(function, Form) ->
    [
        #{
            kind => function,
            name => erl_syntax:atom_value(
                erl_syntax:function_name(Form)
            ),
            arity => erl_syntax:function_arity(Form),
            line => erl_anno:line(erl_syntax:get_pos(Form))
        }
    ];

entity(attribute, Form) ->
    [
        #{
            kind => attribute,
            name => erl_syntax:atom_value(
                erl_syntax:attribute_name(Form)
            ),
            value => unicode:characters_to_binary(
                erl_prettypr:format(Form)
            ),
            line => erl_anno:line(erl_syntax:get_pos(Form))
        }
    ];

entity(_, _) ->
    [].

json_safe(Value) when is_tuple(Value) ->
    unicode:characters_to_binary(
        io_lib:format("~tp", [Value])
    );

json_safe(Value) when is_list(Value) ->
    [json_safe(X) || X <- Value];

json_safe(Value) when is_map(Value) ->
    maps:map(fun(_, X) -> json_safe(X) end, Value);

json_safe(Value) when is_binary(Value) ->
    case unicode:characters_to_binary(Value) of
        Binary when is_binary(Binary) ->
            Binary;
        _ ->
            binary:encode_hex(Value, lowercase)
    end;

json_safe(Value) ->
    Value.
