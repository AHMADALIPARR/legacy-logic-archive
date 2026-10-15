% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
:- use_module(library(lists)).
:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- initialization(main, main).

main :-
    current_prolog_flag(argv, [InPath, OutPath]),
    open(InPath, read, In),
    open(OutPath, write, Out),
    loop(In, Out),
    close(In),
    close(Out).

loop(In, Out) :-
    read_line_to_string(In, S),
    (   S == end_of_file
    ->  true
    ;   atom_json_dict(S, R, []),
        catch(
            setup_call_cleanup(
                open(R.path, read, F),
                read_term(F, T, [syntax_errors(error)]),
                close(F)
            ),
            _,
            T = error
        ),
        (
            T = (:- module(Name, Exports)),
            is_list(Exports)
        ->  findall(
                _{priority: P, type: Ty, name: N},
                (
                    member(op(P, Ty, N), Exports),
                    integer(P),
                    atom(Ty),
                    atom(N)
                ),
                Ops
            ),
            term_string(Name, Module),
            json_write_dict(
                Out,
                _{
                    id: R.id,
                    path: R.path,
                    sha256: R.sha256,
                    module: Module,
                    operators: Ops
                },
                [width(0)]
            ),
            nl(Out)
        ;   true
        ),
        loop(In, Out)
    ).
