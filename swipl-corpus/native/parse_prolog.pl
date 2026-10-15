% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- initialization(main, main).

main :-
    current_prolog_flag(argv, Args),
    main(Args).

main([Input, Output]) :-
    open(Input, read, In, [encoding(utf8)]),
    open(Output, write, Out, [encoding(utf8)]),
    loop(In, Out, 0),
    close(In),
    close(Out).

loop(In, Out, N) :-
    read_line_to_string(In, S),
    (   S == end_of_file
    ->  true
    ;   atom_json_dict(S, R, []),
        N1 is N + 1,
        atom_concat(phase16_read_, N1, M),
        catch(
            parse_file(R.path, M, Terms, Errors),
            E,
            (
                Terms = [],
                message_to_string(E, Msg),
                Errors = [Msg]
            )
        ),
        (Errors = [] -> Status = parsed ; Status = parse_errors),
        length(Terms, Count),
        current_prolog_flag(version_data, V),
        term_string(V, VS),
        D = _{
            id: R.id,
            source_sha256: R.sha256,
            path: R.path,
            language: "Prolog",
            parser: VS,
            status: Status,
            term_count: Count,
            terms: Terms,
            errors: Errors,
            source_execution: false,
            scope: "read_term/3 with literal op directives only; no source consult or directive execution"
        },
        json_write_dict(Out, D, [width(0)]),
        nl(Out),
        flush_output(Out),
        loop(In, Out, N1)
    ).

parse_file(Path, M, Terms, Errors) :-
    M:op(1200, xfx, (:-)),
    setup_call_cleanup(
        open(Path, read, S, [encoding(utf8)]),
        read_terms(S, M, Terms, Errors, 0),
        close(S)
    ).

read_terms(S, M, Terms, Errors, N) :-
    N1 is N + 1,
    (   N > 200000
    ->  Terms = [],
        Errors = ["term limit exceeded"]
    ;   stream_property(S, position(Pos)),
        stream_position_data(line_count, Pos, Line),
        catch(
            read_term(S, T, [module(M), syntax_errors(error)]),
            E,
            T = phase16_error(E)
        ),
        (   T == end_of_file
        ->  Terms = [],
            Errors = []
        ;   T = phase16_error(E)
        ->  message_to_string(E, Msg),
            Terms = Rest,
            Errors = [Msg | Tail],
            read_terms(S, M, Rest, Tail, N1)
        ;   copy_term(T, C),
            numbervars(C, 0, _),
            with_output_to(
                string(Text),
                write_term(
                    C,
                    [quoted(true), numbervars(true), module(M)]
                )
            ),
            entity(T, Entity),
            dependencies(T, Deps),
            Terms = [
                _{
                    line: Line,
                    term: Text,
                    entity: Entity,
                    dependencies: Deps
                }
                | Rest
            ],
            apply_literal_op(T, M),
            read_terms(S, M, Rest, Errors, N1)
        )
    ).

entity(
    (:- module(Name, Exports)),
    _{kind: "module", name: S, exports: E}
) :-
    !,
    term_string(Name, S),
    term_string(Exports, E).

entity((:- _), null) :-
    !.

entity((Head --> _), D) :-
    !,
    head_entity(Head, "dcg_rule", D).

entity((Head :- _), D) :-
    !,
    head_entity(Head, "predicate_clause", D).

entity(Head, D) :-
    head_entity(Head, "fact", D).

head_entity(
    Head,
    Kind,
    _{kind: Kind, name: Name, arity: Arity}
) :-
    callable(Head),
    !,
    functor(Head, Name, Arity).

head_entity(_, _, null).

dependencies((:- G), [_{kind: F, reference: S}]) :-
    nonvar(G),
    functor(G, F, A),
    memberchk(F, [use_module, ensure_loaded, include, reexport]),
    A >= 1,
    arg(1, G, Ref),
    term_string(Ref, S),
    !.

dependencies(_, []).

apply_literal_op((:- op(P, T, N)), M) :-
    integer(P),
    between(0, 1200, P),
    memberchk(T, [xfx, xfy, yfx, fx, fy, xf, yf]),
    (
        atom(N)
    ;
        is_list(N),
        maplist(atom, N)
    ),
    !,
    catch(M:op(P, T, N), _, true).

apply_literal_op(_, _).
