% reasoner/rdf_reasoner.pl
:- use_module(library(semweb/rdf11)).
:- use_module(library(semweb/turtle)).

% ----- Prefixes -----
:- rdf_register_prefix(traffic, 'https://github.com/pmalcius/knowledge-graph-driving-decisions/traffic#').
:- rdf_register_prefix(driving, 'http://purl.net/dscene-kg/drivingscene/v02/').
:- rdf_register_prefix(scene,   'http://purl.net/dscene-kg/scene/v02/').
:- rdf_register_prefix(xsd,     'http://www.w3.org/2001/XMLSchema#').

% ----- Load KB (force Turtle) -----
load_kb :-
    rdf_load('ontology/DSceneKG-Pandaset.ttl', [format(turtle)]),
    rdf_load('ontology/dscenekg_extended.ttl', [format(turtle)]).

/* Scene facts asserted at runtime:
   in_zone(ZoneA).
   present_sign(SignA).
   current_time(MinFromMidnight).
   intended_action(ActionA).
*/

% =======================
% IRI utilities
% =======================
iri_to_atom(Term, Atom) :-
    ( atom(Term) -> Atom = Term
    ; rdf_iri(Term, Atom)
    ).

iri_fragment(Term, FragAtom) :-
    iri_to_atom(Term, IRIAtom),
    ( sub_atom(IRIAtom, _, _, After, '#')
    -> sub_atom(IRIAtom, _, After, 0, FragAtom)
    ;  atomic_list_concat(Parts, '/', IRIAtom),
       last(Parts, FragAtom)
    ).

% =======================
% Fragment → canonical atom maps
% =======================
frag_action('RightOnRed',       right_on_red).
frag_sign('NoTurnOnRed',        no_turn_on_red).
frag_zone('SchoolZone',         school_zone).

action_matches(ActionIRI, Canon) :-
    iri_fragment(ActionIRI, Frag), frag_action(Frag, Canon).
sign_matches(SignIRI, Canon) :-
    iri_fragment(SignIRI, Frag), frag_sign(Frag, Canon).
zone_matches(ZoneIRI, Canon) :-
    iri_fragment(ZoneIRI, Frag), frag_zone(Frag, Canon).

% =======================
% Time handling (robust)
% =======================
% Accept several literal shapes:
%  - time(H,M,S,Offset)          (rdf11 canonical)
%  - literal(type(xsd:time,Lex)) (older shape)
%  - atom "HH:MM[:SS]"
time_obj_to_min(Obj, Min) :-
    ( Obj = time(H,M,_S,_Off) ->
        Min is H*60 + M
    ; Obj = literal(type(_,Lex)) ->
        atom_time_to_min(Lex, Min)
    ; atom(Obj) ->
        atom_time_to_min(Obj, Min)
    ; string(Obj) ->
        atom_string(A, Obj), atom_time_to_min(A, Min)
    ).

atom_time_to_min(Atom, Min) :-
    atom_string(Atom, S),
    split_string(S, ":", "", Parts),
    ( Parts = [HH,MM]     -> number_string(H, HH), number_string(M, MM), Min is H*60 + M
    ; Parts = [HH,MM,_SS] -> number_string(H, HH), number_string(M, MM), Min is H*60 + M
    ).

% Fragment fallback table
tw_bounds_by_fragment('DropOff_0730_0900', 450, 540).  % 07:30–09:00

% NEW: try typed/untyped read; if that fails or is out-of-range, also try fragment fallback
time_in_window(Min, TW) :-
    (   % Try reading times from RDF (typed or untyped)
        ( rdf(TW, traffic:startsAtTime, S0) ),
        ( rdf(TW, traffic:endsAtTime,   E0) ),
        time_obj_to_min(S0, SMin),
        time_obj_to_min(E0, EMin),
        (   Min >= SMin, Min =< EMin
        ->  true
        ;   % Not in that range? fall through to fragment fallback
            fail
        )
    )
    ;
    (
        iri_fragment(TW, Frag),
        tw_bounds_by_fragment(Frag, FS, FE),
        % tiny debug to stderr so we can see what fallback used
        format(user_error, "[DEBUG] Fallback TW ~w => ~w-~w~n", [Frag, FS, FE]),
        Min >= FS, Min =< FE
    ).

% =======================
% Condition checkers
% =======================
cond_zone_ok(Rule) :-
    ( rdf(Rule, traffic:appliesInZone, ZoneIRI)
      -> zone_matches(ZoneIRI, ZoneA), in_zone(ZoneA)
      ;  true ).

cond_sign_ok(Rule) :-
    ( rdf(Rule, traffic:requiresSign, SignIRI)
      -> sign_matches(SignIRI, SignA), present_sign(SignA)
      ;  true ).

cond_time_ok(Rule) :-
    ( rdf(Rule, traffic:appliesDuring, TW)
      -> current_time(Min), time_in_window(Min, TW)
      ;  true ).

% =======================
% Rule applicability
% =======================
rule_applies(Rule, ActionA, Kind) :-
    rdf(Rule, rdf:type, traffic:'TrafficRule'),
    ( rdf(Rule, traffic:prohibitsAction, ActionIRI), Kind = prohibits
    ; rdf(Rule, traffic:permitsAction,   ActionIRI), Kind = permits
    ),
    action_matches(ActionIRI, ActionA),
    cond_zone_ok(Rule),
    cond_sign_ok(Rule),
    cond_time_ok(Rule).

% =======================
% Decision semantics
% =======================
illegal(ActionA, Rule) :-
    intended_action(ActionA),
    rule_applies(Rule, ActionA, prohibits).

legal(ActionA) :-
    intended_action(ActionA),
    \+ illegal(ActionA, _).

explain(illegal, Rule, Why) :-
    format(string(Why), "Prohibiting rule applies (~w) under current zone/sign/time.", [Rule]).
explain(legal,  _,   "No prohibiting rule applies for this context.").

% Debug: dump rule by rule
dump_rules_for(ActionA) :-
    format(user_error, "~n[DEBUG] Rules for action '~w':~n", [ActionA]),
    forall(
      ( rdf(R, rdf:type, traffic:'TrafficRule'),
        ( rdf(R, traffic:prohibitsAction, Airi) ; rdf(R, traffic:permitsAction, Airi) )
      ),
      (
        ( action_matches(Airi, ActionA) -> Amatch = true ; Amatch = false ),
        ( rdf(R, traffic:appliesInZone, Zi) -> (zone_matches(Zi, Z), (in_zone(Z) -> Zok=true ; Zok=false)) ; (Zi=none, Zok=true) ),
        ( rdf(R, traffic:requiresSign, Si) -> (sign_matches(Si, S), (present_sign(S) -> Sok=true ; Sok=false)) ; (Si=none, Sok=true) ),
        ( rdf(R, traffic:appliesDuring, Ti) -> (current_time(M), (time_in_window(M, Ti) -> Tok=true ; Tok=false)) ; (Ti=none, Tok=true) ),
        format(user_error, "  Rule=~w | A=~w (~w) | Z=~w (~w) | S=~w (~w) | T=~w (~w)~n",
               [R, Airi, Amatch, Zi, Zok, Si, Sok, Ti, Tok])
      )
    ).

decide(ActionA, illegal, Why) :- illegal(ActionA, Rule), !, explain(illegal, Rule, Why).
decide(ActionA, legal,  Why)  :-
    ( dump_rules_for(ActionA) -> true ; true ),
    explain(legal,  _,   Why).