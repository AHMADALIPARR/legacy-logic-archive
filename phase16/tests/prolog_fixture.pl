% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
% Authored verification fixture; not historical source.

:- module(example, [pair/2]).
:- op(600, xfx, links).

'quoted predicate'(X, nested(a, X)) :-
    X = 'value.with.dot'.

pair(X,
     Y) :-
    X links Y.

list --> [item], { true }.

:- open('tests/prolog_should_not_execute', write, _).
