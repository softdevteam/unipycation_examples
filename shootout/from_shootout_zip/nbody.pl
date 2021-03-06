% ----------------------------------------------------------------------
% The Computer Language Shootout
% http://shootout.alioth.debian.org/
%
% Contributed by Anthony Borla
% ----------------------------------------------------------------------

main :-
  cmdlNumArg(1, N),
  main(N).

main(N):-
  make_bodies(Bodies),

  offset_momentum(Bodies),
  energy(Bodies, EnergyStart),
  advance(Bodies, N, 0.01),
  energy(Bodies, EnergyAfter),

  format('~9f~N~9f~N', [EnergyStart, EnergyAfter]),
  drop_bodies(Bodies).

% ------------------------------- %

offset_momentum(Bodies) :-
  setvar(px, 0.0), setvar(py, 0.0), setvar(pz, 0.0),

  forall(member(E, Bodies),
    (getvar(E, [X, Y, Z, VX, VY, VZ, Mass]), getvar(px, PX), getvar(py, PY), getvar(pz, PZ),
    PX1 is PX + VX * Mass, PY1 is PY + VY * Mass, PZ1 is PZ + VZ * Mass,
    setvar(px, PX1), setvar(py, PY1), setvar(pz, PZ1))),

  getvar(solar_mass, SOLAR_MASS),
  getvar(sun, [X, Y, Z, VX, VY, VZ, Mass]), getvar(px, PX), getvar(py, PY), getvar(pz, PZ),
  VX1 is -(PX / SOLAR_MASS), VY1 is -(PY / SOLAR_MASS), VZ1 is -(PZ / SOLAR_MASS),
  setvar(sun, [X, Y, Z, VX1, VY1, VZ1, Mass]),

  dropvar(px), dropvar(py), dropvar(pz).

% ------------------------------- %

energy(Bodies, Energy) :-
  setvar(c, 0.0),

  forall(head_and_tail(E, T, Bodies),
    (getvar(E, [X, Y, Z, VX, VY, VZ, Mass]), getvar(c, C),
    C1 is C + 0.5 * Mass * (VX * VX + VY * VY + VZ * VZ),
    setvar(c, C1),

      (forall(member(ET, T),
        (getvar(ET, [XT, YT, ZT, _, _, _, MassT]), getvar(c, CT),
        DX is X - XT, DY is Y - YT, DZ is Z - ZT,
        DISTANCE is sqrt(DX * DX + DY * DY + DZ * DZ),
        CT1 is CT - (Mass * MassT) / DISTANCE,
        setvar(c, CT1)))))),

  getvar(c, Energy), dropvar(c).

% ------------------------------- %

advance(Bodies, Repetitions, DT) :-
  setvar(counter, 1),

  repeat,
    getvar(counter, I), I1 is I + 1, setvar(counter, I1),

    forall(head_and_tail(E, T, Bodies),
      (forall(member(ET, T),
        (getvar(E, [X, Y, Z, VX, VY, VZ, Mass]),
        getvar(ET, [XT, YT, ZT, VXT, VYT, VZT, MassT]),
        DX is X - XT, DY is Y - YT, DZ is Z - ZT,
        DISTANCE is sqrt(DX * DX + DY * DY + DZ * DZ),
        Mag is DT / (DISTANCE * DISTANCE * DISTANCE),
        VX1 is VX - DX * MassT * Mag, VY1 is VY - DY * MassT * Mag, VZ1 is VZ - DZ * MassT * Mag,
        VXT1 is VXT + DX * Mass * Mag, VYT1 is VYT + DY * Mass * Mag, VZT1 is VZT + DZ * Mass * Mag,
        setvar(E, [X, Y, Z, VX1, VY1, VZ1, Mass]),
        setvar(ET, [XT, YT, ZT, VXT1, VYT1, VZT1, MassT]))))),

    forall(member(E, Bodies),
      (getvar(E, [X, Y, Z, VX, VY, VZ, Mass]),
      X1 is X + DT * VX, Y1 is Y + DT * VY, Z1 is Z + DT * VZ,
      setvar(E, [X1, Y1, Z1, VX, VY, VZ, Mass]))),

  I >= Repetitions,

  dropvar(counter).

% ------------------------------- %

make_bodies(Bodies) :-
  setvar(solar_mass, 3.9478417604357432000e+01), getvar(solar_mass, SOLAR_MASS),
  Data =
  [
    (sun:[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SOLAR_MASS]),
    (jupiter:[4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01, 6.06326392995832020e-01, 2.811986844916260200e+00, -2.5218361659887636e-02, 3.7693674870389486e-02]),
    (saturn:[8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01, -1.010774346178792400e+00, 1.825662371230411900e+00, 8.415761376584154e-03, 1.1286326131968767e-02]),
    (uranus:[1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01, 1.082791006441535600e+00, 8.68713018169607890e-01, -1.0832637401363636e-02, 1.723724057059711e-03]),
    (neptune:[1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01, 9.79090732243897980e-01, 5.94698998647676060e-01, -3.4755955504078104e-02, 2.033686869924631e-03])
  ],
  forall(member((Key:Values), Data), setvar(Key, Values)),
  collect_keys(Data, Bodies).

% ------------- %

drop_bodies(Bodies) :-
  dropvar(solar_mass),
  forall(member(E, Bodies), dropvar(E)).

% ------------------------------- %

%%%z getvar(Id, Value) :- nb_getval(Id, Value).
%%%z setvar(Id, Value) :- nb_setval(Id, Value).
%%%z dropvar(Id) :- nb_delete(Id).

getvar(Id, Value) :- global_get(Id, Value).
setvar(Id, Value) :- global_set(Id, Value).
dropvar(Id) :- global_del(Id).


% ------------- %

collect_keys(List, Values) :-
  collect_keys_(List, Values).

collect_keys_([], []).
collect_keys_([(H:_)|T], K) :- K = [H|T1], collect_keys_(T, T1).

% ------------- %

head_and_tail(X, T, [X|T]).
head_and_tail(X, T1, [_|T]) :- head_and_tail(X, T1, T).

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
