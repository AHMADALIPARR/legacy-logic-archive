% SPDX-License-Identifier: GPL-3.0-or-later
% Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
% Authored by Ahmad Ali Parr.
-module(erlang_fixture).
-include("not_loaded.hrl").
-define(IDENTITY(X), X).
-export([run/1]).

run(X) ->
    ?IDENTITY({ok, X}).
