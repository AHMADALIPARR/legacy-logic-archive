# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
package Structure;

use strict;
use warnings;

# Partial extraction: one-line declarations and literal imports.
sub extract {
    my ($language, $bytes) = @_;

    my (@entities, @dependencies);
    my $line = 0;

    for my $text (split /\n/, $bytes) {
        $line++;

        my ($kind, $name);

        next if $text =~ /^\s*(?:%|--|\/\/)/;

        if ($language eq 'Erlang') {
            ($kind, $name) = ('module', $1)
                if $text =~ /^-module\(\s*([\w@]+)/;

            ($kind, $name) = ('function_clause', $1)
                if $text =~ /^([a-z][\w@]*)\s*\(.*(?:->|when\b)/;

            push @dependencies, {
                line      => $line,
                reference => $1,
                kind      => 'include',
            } if $text =~ /^-include(?:_lib)?\(\s*"([^"]+)"/;
        }
        elsif ($language eq 'Elixir') {
            ($kind, $name) = ($1, $2)
                if $text =~ /^\s*(defmodule|defp?|defmacro|defmacrop|defprotocol|defimpl)\s+([\w.!?]+)/;

            push @dependencies, {
                line      => $line,
                reference => $2,
                kind      => $1,
            } if $text =~ /^\s*(use|import|require|alias)\s+([\w.]+)/;
        }
        elsif ($language eq 'Prolog') {
            ($kind, $name) = ('predicate_clause', $1)
                if $text =~ /^([a-z][\w]*)\s*(?:\(|:-|\.)/;

            push @dependencies, {
                line      => $line,
                reference => $2,
                kind      => $1,
            } if $text =~ /^\s*:-\s*(use_module|ensure_loaded|include)\(([^\n]+)\)/;
        }
        elsif ($language eq 'Ada' || $language eq 'Pascal') {
            ($kind, $name) = (lc($1), $2)
                if $text =~ /^\s*(package(?:\s+body)?|procedure|function|program|unit|type)\s+([\w.]+)/i;

            push @dependencies, {
                line      => $line,
                reference => $2,
                kind      => lc($1),
            } if $text =~ /^\s*(with|uses)\s+([^;]+);/i;
        }
        elsif ($language =~ /^C/) {
            push @dependencies, {
                line      => $line,
                reference => $1,
                kind      => 'include',
            } if $text =~ /^\s*#\s*include\s*[<"]([^>"]+)/;

            ($kind, $name) = ('function_candidate', $1)
                if $text =~ /^\w[\w\s*]+\s+(\w+)\s*\([^;]*\)\s*\{/;
        }

        push @entities, {
            kind => $kind,
            name => $name,
            line => $line,
        } if defined $name;
    }

    return (\@entities, \@dependencies);
}

1;
