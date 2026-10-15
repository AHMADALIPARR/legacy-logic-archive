% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
:- use_module(library(lists)).
:- use_module(library(apply)).

:- dynamic baseline_op/3.
:- dynamic registry_op/4.
:- dynamic profile_op/4.

setup_context :-
    forall(
        current_op(P, T, N),
        assertz(baseline_op(P, T, N))
    ),
    load_json_lines(
        'evidence/EXPORTED_OPERATOR_REGISTRY.jsonl',
        registry_row
    ),
    load_json_lines(
        'evidence/PROFILE_OPERATORS.jsonl',
        profile_row
    ).

load_json_lines(Path, Pred) :-
    setup_call_cleanup(
        open(Path, read, S),
        load_rows(S, Pred),
        close(S)
    ).

load_rows(S, Pred) :-
    read_line_to_string(S, Line),
    (   Line == end_of_file
    ->  true
    ;   atom_json_dict(Line, D, []),
        call(Pred, D),
        load_rows(S, Pred)
    ).

registry_row(D) :-
    file_base_name(D.path, File),
    file_name_extension(Base, pl, File),
    forall(
        member(O, D.operators),
        (
            atom_string(T, O.type),
            atom_string(N, O.name),
            assertz(registry_op(Base, O.priority, T, N)),
            atom_string(Alias, D.module),
            (
                Alias == Base
            ->  true
            ;   assertz(registry_op(Alias, O.priority, T, N))
            )
        )
    ).

profile_row(D) :-
    atom_string(Profile, D.profile),
    atom_string(T, D.type),
    atom_string(N, D.name),
    assertz(profile_op(Profile, D.priority, T, N)).

initialize_context(Path, M) :-
    forall(
        baseline_op(P, T, N),
        safe_operator(M, P, T, N)
    ),
    (
        sub_atom(Path, _, _, _, 'gprolog-1.4.4')
    ->  forall(
            profile_op(gnu_prolog, P, T, N),
            safe_operator(M, P, T, N)
        )
    ;   true
    ),
    (
        sub_atom(Path, _, _, _, 'swi-packages-xpce')
    ->  forall(
            profile_op(xpce_compilation_operators, P, T, N),
            safe_operator(M, P, T, N)
        ),
        import_registry(pce, M)
    ;   true
    ),
    (
        sub_atom(Path, _, _, _, '/dialect/ciao/')
    ->  apply_profile(ciao_assertions, M)
    ;   true
    ).

safe_operator(M, P, T, N) :-
    integer(P),
    between(0, 1200, P),
    memberchk(T, [xfx, xfy, yfx, fx, fy, xf, yf]),
    atom(N),
    !,
    catch(M:op(P, T, N), _, true).

safe_operator(_, _, _, _).

import_registry(Ref, M) :-
    (
        Ref = library(Spec)
    ->  term_string(Spec, SS),
        split_string(SS, "/", "", Parts),
        last(Parts, BS),
        atom_string(Base, BS)
    ;   atom(Ref)
    ->  file_base_name(Ref, B),
        file_name_extension(Base, _, B)
    ;   fail
    ),
    !,
    forall(
        registry_op(Base, P, T, N),
        safe_operator(M, P, T, N)
    ).

import_registry(_, _).

context_directive((:- module(_, Exports)), M) :-
    is_list(Exports),
    !,
    forall(
        member(op(P, T, N), Exports),
        safe_operator(M, P, T, N)
    ).

context_directive((:- use_module(Ref)), M) :-
    !,
    import_registry(Ref, M).

context_directive((:- reexport(Ref)), M) :-
    !,
    import_registry(Ref, M).

context_directive((:- include(chr_op)), M) :-
    !,
    apply_profile(chr_literal_include, M).

context_directive(_, _).

apply_profile(Profile, M) :-
    forall(
        profile_op(Profile, P, T, N),
        safe_operator(M, P, T, N)
    ).
