# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
# Authored by Ahmad Ali Parr.
# NOTE: assistant-reconstructed, NOT a user-supplied verbatim file. Inferred
# duplicate of historical-corpus/bin/structure.pm: swipl-corpus/bin/normalize.pl does
# `use lib $FindBin::Bin; use structure;`, so this module must exist in
# swipl-corpus/bin/; the extractor has zero phase-specific content.
package Structure;
use strict; use warnings;
# Deliberately partial: one-line declarations and literal imports only.
sub extract {
 my($language,$b)=@_; my (@entities,@deps); my $line=0;
 for my $l(split /\n/,$b){$line++;my($kind,$name);
 next if $l =~ /^\s*(?:%|--|\/\/)/;
 if($language eq 'Erlang'){($kind,$name)=('module',$1) if $l=~/^-module\(\s*([\w@]+)/;($kind,$name)=('function_clause',$1) if $l=~/^([a-z][\w@]*)\s*\(.*(?:->|when\b)/;push @deps,{line=>$line,reference=>$1,kind=>'include'} if $l=~/^-include(?:_lib)?\(\s*"([^"]+)"/;}
 elsif($language eq 'Elixir'){($kind,$name)=($1,$2) if $l=~/^\s*(defmodule|defp?|defmacro|defmacrop|defprotocol|defimpl)\s+([\w.!?]+)/;push @deps,{line=>$line,reference=>$2,kind=>$1} if $l=~/^\s*(use|import|require|alias)\s+([\w.]+)/;}
 elsif($language eq 'Prolog'){($kind,$name)=('predicate_clause',$1) if $l=~/^([a-z][\w]*)\s*(?:\(|:-|\.)/;push @deps,{line=>$line,reference=>$2,kind=>$1} if $l=~/^\s*:-\s*(use_module|ensure_loaded|include)\(([^\n]+)\)/;}
 elsif($language eq 'Ada'||$language eq 'Pascal'){($kind,$name)=(lc($1),$2) if $l=~/^\s*(package(?:\s+body)?|procedure|function|program|unit|type)\s+([\w.]+)/i;push @deps,{line=>$line,reference=>$2,kind=>lc($1)} if $l=~/^\s*(with|uses)\s+([^;]+);/i;}
 elsif($language=~/^C/){push @deps,{line=>$line,reference=>$1,kind=>'include'} if $l=~/^\s*#\s*include\s*[<"]([^>"]+)/;($kind,$name)=('function_candidate',$1) if $l=~/^\w[\w\s*]+\s+(\w+)\s*\([^;]*\)\s*\{/;}
 push @entities,{kind=>$kind,name=>$name,line=>$line} if defined $name;
 }
 return (\@entities,\@deps);
}
1;
