% ----------------------------------------------------------------------
% The Great Computer Language Shootout
% http://shootout.alioth.debian.org/
%
% This is a slightly-modified version of the exising nsieve implementation
% differing only in the mechanism used to mimic array creation and
% access. This version [when compared to existing version]:
%
% * Makes only modest demands of the global stack, so should execute using
%   default values, at least up to a load of N = 9. However, its heap
%   memory demands make it prone to thrashing [existing version is more
%   stable as long as a sufficiently large stack size is specified]
%
% * Execution times are on par at up to N = 6, then diverge quite
%   dramatically [e.g. at N = 8 this version is roughly twice as fast as
%   exisitng version]
%
% Contributed by Anthony Borla
% ----------------------------------------------------------------------

main :-
  cmdlNumArg(1, N),
  main(N).

main(N):-
  N1 is 10000 << N,
  N2 is 10000 << (N - 1),
  N3 is 10000 << (N - 2),

  calcAndshowSieve(N1),
  calcAndshowSieve(N2),
  calcAndshowSieve(N3).

% ------------------------------- %

calcAndshowSieve(N) :-
  make_array(N, 1),
  nsieve(2, N, 0, R),
  format('Primes up to~t~w~21|~t~w~30|~n', [N, R]).

% ------------------------------- %

nsieve(ASize, ASize, R, R) :- !.
nsieve(N, ASize, A, R) :- not(is_slot(N)), N1 is N + 1, !, nsieve(N1, ASize, A, R).
nsieve(N, ASize, A, R) :- clear_sieve(N, N, ASize), A1 is A + 1, N1 is N + 1, !, nsieve(N1, ASize, A1, R).

% ------------- %

clear_sieve(N, M, ASize) :- N1 is N + M, clear_sieve_(N1, M, ASize).

% ------------- %

clear_sieve_(N, _, ASize) :- ASize < N, !.
clear_sieve_(N, M, ASize) :- clear_slot(N), N1 is N + M, !, clear_sieve_(N1, M, ASize).

% ------------------------------- %

make_array(N, V) :- fill_array(N, V).

% ------------- %

fill_array(0, _) :- !.
fill_array(N, V) :- flag(N, _, V), N1 is N - 1, !, fill_array(N1, V).

% ------------- %

set_slot(N) :- flag(N, _, 1).
clear_slot(N) :- flag(N, _, 0).
is_slot(N) :- flag(N, V, V), V =:= 1.

% ------------------------------- %
flag(Key,Old,New):-
  is_global_heap(Key),!,
  global_heap_get(Key,Old),
  Val is New,
  global_heap_set(Key,Val).
flag(Key,Old,New):-
  Val is New,
  global_heap_set(Key,Val).


% ------------------------------- %
%%%z argument_value(N, Arg) :-
%%%z   current_prolog_flag(argv, Cmdline), append(_, [--|UserArgs], Cmdline),
%%%z   Nth is N - 1, nth0(Nth, UserArgs, Arg).

%%%z cmdlNumArg(Nth, N) :-
%%%z   argument_value(Nth, Arg), catch(atom_number(Arg, N), _, fail) ; halt(1).

argument_value(N, Arg) :-
  get_main_args(Cmdline), 
  append(_, [--|UserArgs], Cmdline),
  Nth is N - 1, nth0(Nth, UserArgs, Arg).

cmdlNumArg(Nth, N) :-
  argument_value(Nth, Arg), 
  catch(atom_number(Arg, N), _, fail) ; halt(1).

atom_number(Arg,N):-
   atom_codes(Arg,Codes),
   number_codes(N,Codes).

