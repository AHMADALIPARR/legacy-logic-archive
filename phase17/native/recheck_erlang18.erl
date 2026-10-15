% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
-module(recheck_erlang18).
-export([main/0]).

main() ->
    [Input, Output] = init:get_plain_arguments(),
    {ok, In} = file:open(Input, [read, binary]),
    {ok, Out} = file:open(Output, [write, binary]),
    loop(In, Out, 0),
    file:close(In),
    file:close(Out),
    halt().

loop(In, Out, N) ->
    case file:read_line(In) of
        eof ->
            ok;

        {ok, Line} ->
            [ID, Path, Hash] =
                binary:split(trim(Line), <<"\t">>, [global]),

            File = unicode:characters_to_list(Path),
            K = N + 1,

            Artifact =
                "normalized/erlang18/"
                ++ integer_to_list(K)
                ++ ".etf",

            {Status, Errors} =
                try
                    parse(File, Artifact)
                catch
                    C:E ->
                        file:write_file(
                            Artifact,
                            term_to_binary({C, E})
                        ),
                        {"parser_exception", 1}
                end,

            file:write(
                Out,
                [
                    ID, "\t",
                    Path, "\t",
                    Hash, "\t",
                    Status, "\t",
                    integer_to_list(Errors), "\t",
                    Artifact, "\n"
                ]
            ),

            loop(In, Out, K)
    end.

trim(B) ->
    binary:replace(B, <<"\n">>, <<>>, [global]).

parse(Path, Artifact) ->
    case epp_dodger:parse_file(Path, [{no_fail, false}]) of
        {ok, Forms} ->
            Errors = [
                F
                || F <- Forms,
                   erl_syntax:type(F) =:= error_marker
            ],

            ok = file:write_file(
                Artifact,
                term_to_binary(Forms)
            ),

            case Errors of
                [] ->
                    {"parsed", 0};

                _ ->
                    {"parse_errors", length(Errors)}
            end;

        Other ->
            file:write_file(
                Artifact,
                term_to_binary(Other)
            ),
            {"parse_errors", 1}
    end.
