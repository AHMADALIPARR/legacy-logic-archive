% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
:- module(phase17_fixture, [op(700, xfx, likes)]).

:- initialization(
    throw(archived_directive_must_not_execute)
).

a likes b.

'quoted predicate'(X) --> [X].
