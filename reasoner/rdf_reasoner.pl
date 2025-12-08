% reasoner/rdf_reasoner.pl
:- use_module(library(semweb/rdf11)).
:- use_module(library(semweb/turtle)).

% ----- Prefixes -----
:- rdf_register_prefix(traffic, 'https://github.com/pmalcius/knowledge-graph-driving-decisions/traffic#').
:- rdf_register_prefix(driving, 'http://purl.net/dscene-kg/drivingscene/v02/').
:- rdf_register_prefix(scene,   'http://purl.net/dscene-kg/scene/v02/').
:- rdf_register_prefix(xsd,     'http://www.w3.org/2001/XMLSchema#').

% Scene-level facts asserted at runtime from Python
:- dynamic in_zone/1.
:- dynamic present_sign/1.
:- dynamic current_time/1.
:- dynamic intended_action/1.
:- dynamic pedestrians_present/0.
:- dynamic vehicle_speed/1.

% ----- Load KB (force Turtle) -----
load_kb :-
    rdf_load('ontology/DSceneKG-Pandaset.ttl', [format(turtle)]),
    rdf_load('ontology/dscenekg_extended.ttl', [format(turtle)]).

/* Scene facts asserted at runtime:
   in_zone(ZoneA).
   present_sign(SignA).
   current_time(MinFromMidnight).
   intended_action(ActionA).
   pedestrians_present.
   vehicle_speed(Speed).
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
frag_sign('StopSign',           stop_sign).

frag_zone('SchoolZone',         school_zone).
frag_zone('CrosswalkZone',      crosswalk_zone).

action_matches(ActionIRI, Canon) :-
    iri_fragment(ActionIRI, Frag),
    frag_action(Frag, Canon).

sign_matches(SignIRI, Canon) :-
    iri_fragment(SignIRI, Frag),
    frag_sign(Frag, Canon).

zone_matches(ZoneIRI, Canon) :-
    iri_fragment(ZoneIRI, Frag),
    frag_zone(Frag, Canon).

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
        atom_string(A, Obj),
        atom_time_to_min(A, Min)
    ).

atom_time_to_min(Atom, Min) :-
    atom_string(Atom, S),
    split_string(S, ":", "", Parts),
    ( Parts = [HH,MM]
      -> number_string(H, HH),
         number_string(M, MM),
         Min is H*60 + M
    ; Parts = [HH,MM,_SS]
      -> number_string(H, HH),
         number_string(M, MM),
         Min is H*60 + M
    ).

% Fragment fallback table
tw_bounds_by_fragment('DropOff_0730_0900', 450, 540).  % 07:30–09:00

% Try typed/untyped read; if that fails or is out-of-range, also try fragment fallback
time_in_window(Min, TW) :-
    (   % Try reading times from RDF (typed or untyped)
        rdf(TW, traffic:startsAtTime, S0),
        rdf(TW, traffic:endsAtTime,   E0),
        time_obj_to_min(S0, SMin),
        time_obj_to_min(E0, EMin),
        Min >= SMin,
        Min =< EMin
    )
    ;
    (
        iri_fragment(TW, Frag),
        tw_bounds_by_fragment(Frag, FS, FE),
        % tiny debug to stderr so we can see what fallback used
        format(user_error, "[DEBUG] Fallback TW ~w => ~w-~w~n", [Frag, FS, FE]),
        Min >= FS,
        Min =< FE
    ).

% =======================
% Condition checkers
% =======================
cond_zone_ok(Rule) :-
    ( rdf(Rule, traffic:appliesInZone, ZoneIRI)
      -> zone_matches(ZoneIRI, ZoneA),
         in_zone(ZoneA)
      ;  true ).

cond_sign_ok(Rule) :-
    ( rdf(Rule, traffic:requiresSign, SignIRI)
      -> sign_matches(SignIRI, SignA),
         present_sign(SignA)
      ;  true ).

cond_time_ok(Rule) :-
    ( rdf(Rule, traffic:appliesDuring, TW)
      -> current_time(Min),
         time_in_window(Min, TW)
      ;  true ).

% =======================
% Rule applicability (generic)
% =======================
% rule_applies(+Rule, +ActionCanonical, -Kind)
%   Succeeds if Rule is a TrafficRule that either prohibits or permits
%   the given canonical action and all zone/sign/time conditions hold.
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
% School-zone right-on-red rules
% =======================
% Currently handled entirely through the generic rule_applies/3 predicate
% using the TrafficRule individuals defined in the ontology.

% =======================
% Stop sign rules (scaffolding + enforcement)
% =======================
% must_stop_before_proceeding/1:
%   Skeleton predicate that can be used for future "did the car actually stop?"
%   reasoning. Right now it just logs when a StopSign rule is relevant.
stop_sign_rule(Rule) :-
    rdf(Rule, rdf:type, traffic:'TrafficRule'),
    rdf(Rule, traffic:requiresSign, SignIRI),
    sign_matches(SignIRI, stop_sign).

must_stop_before_proceeding(ActionA) :-
    intended_action(ActionA),
    stop_sign_rule(Rule),
    present_sign(stop_sign),
    % Reuse generic condition checkers for zone/time if attached
    cond_zone_ok(Rule),
    cond_time_ok(Rule),
    % Placeholder: just print a debug message.
    format(user_error,
           "[DEBUG] must_stop_before_proceeding scaffold triggered for action ~w, rule ~w~n",
           [ActionA, Rule]).

% NEW: stop_sign_violation/2
%   Encodes the idea that if there is a StopSign rule, the StopSign is present,
%   and the driver is performing some movement (e.g., right_on_red), then we
%   treat the behavior as illegal unless proven otherwise.
stop_sign_violation(ActionA, Rule) :-
    intended_action(ActionA),
    stop_sign_rule(Rule),
    present_sign(stop_sign),
    cond_zone_ok(Rule),
    cond_time_ok(Rule),
    format(user_error,
           "[DEBUG] stop_sign_violation triggered for action ~w, rule ~w~n",
           [ActionA, Rule]).

% =======================
% Crosswalk / yield rules (scaffolding)
% =======================
% yield_to_pedestrians/2:
%   Skeleton predicate intended for future "yield at crosswalk" behavior.
%   Currently just checks for a crosswalk rule and pedestrians_present/0,
%   and emits a debug message. It does not affect legality yet.
crosswalk_rule(Rule) :-
    rdf(Rule, rdf:type, traffic:'TrafficRule'),
    rdf(Rule, traffic:appliesInZone, ZoneIRI),
    zone_matches(ZoneIRI, crosswalk_zone).

yield_to_pedestrians(ActionA, Rule) :-
    intended_action(ActionA),
    pedestrians_present,
    crosswalk_rule(Rule),
    format(user_error,
           "[DEBUG] yield_to_pedestrians scaffold hit for action ~w, rule ~w~n",
           [ActionA, Rule]).

% =======================
% Explanation components
% =======================
% explain_rule_components(+Rule, -ZoneStatus, -SignStatus, -TimeStatus, -ActionStatus)
%   Collects a structured view of how a rule matched (or did not match)
%   the current scene. Used to build richer explanation strings.
explain_rule_components(Rule, ZoneStatus, SignStatus, TimeStatus, ActionStatus) :-
    % Zone status
    ( rdf(Rule, traffic:appliesInZone, ZoneIRI)
      -> zone_matches(ZoneIRI, ZCanon),
         ( in_zone(ZCanon)
           -> ZoneStatus = matches_zone(ZCanon)
           ;  ZoneStatus = mismatched_zone(ZCanon)
         )
      ;  ZoneStatus = no_zone_constraint
    ),
    % Sign status
    ( rdf(Rule, traffic:requiresSign, SignIRI)
      -> sign_matches(SignIRI, SCanon),
         ( present_sign(SCanon)
           -> SignStatus = matches_sign(SCanon)
           ;  SignStatus = missing_sign(SCanon)
         )
      ;  SignStatus = no_sign_constraint
    ),
    % Time status
    ( rdf(Rule, traffic:appliesDuring, TW)
      -> current_time(Min),
         ( time_in_window(Min, TW)
           -> TimeStatus = in_time_window(TW)
           ;  TimeStatus = outside_time_window(TW)
         )
      ;  TimeStatus = no_time_constraint
    ),
    % Action status
    ( rdf(Rule, traffic:prohibitsAction, Airi)
      -> ( action_matches(Airi, ACanon)
           -> ActionStatus = prohibits_action(ACanon)
           ;  ActionStatus = prohibiting_unknown_action(Airi)
         )
    ; rdf(Rule, traffic:permitsAction, Airi)
      -> ( action_matches(Airi, ACanon)
           -> ActionStatus = permits_action(ACanon)
           ;  ActionStatus = permitting_unknown_action(Airi)
         )
      ;  ActionStatus = no_action_constraint
    ).

% =======================
% Decision semantics
% =======================
% illegal(+ActionCanonical, -Rule)
%   Succeeds if either:
%     * an ontology TrafficRule explicitly prohibits the action, OR
%     * the local stop_sign_violation rule fires.
illegal(ActionA, Rule) :-
    intended_action(ActionA),
    ( rule_applies(Rule, ActionA, prohibits)
    ; stop_sign_violation(ActionA, Rule)
    ).

legal(ActionA) :-
    intended_action(ActionA),
    \+ illegal(ActionA, _).

% Build human-readable explanations using the structured components
explain(illegal, Rule, Why) :-
    explain_rule_components(Rule, ZStatus, SStatus, TStatus, AStatus),
    format(string(Why),
           "Prohibiting rule applies (~w). Action: ~w, Zone: ~w, Sign: ~w, Time: ~w.",
           [Rule, AStatus, ZStatus, SStatus, TStatus]).
explain(legal,  _,   "No prohibiting rule applies for this context.").

% =======================
% Debug: dump rules and scaffold categories
% =======================
% dump_rules_for(+ActionCanonical)
%   Prints a detailed view of each TrafficRule, including whether it
%   is a generic rule, a stop-sign scaffold, or a crosswalk scaffold.
dump_rules_for(ActionA) :-
    format(user_error, "~n[DEBUG] Rules for action '~w':~n", [ActionA]),
    forall(
      rdf(R, rdf:type, traffic:'TrafficRule'),
      (
        % Action / kind
        ( rdf(R, traffic:prohibitsAction, Airi)
          -> AKind = prohibits
        ; rdf(R, traffic:permitsAction, Airi)
          -> AKind = permits
        ; Airi = none,
          AKind = none
        ),
        ( Airi == none
          -> Amatch = 'n/a'
          ;  ( action_matches(Airi, ActionA)
               -> Amatch = true
               ;  Amatch = false
             )
        ),
        % Zone status
        ( rdf(R, traffic:appliesInZone, Zi)
          -> ( zone_matches(Zi, Z),
               ( in_zone(Z) -> Zok = true ; Zok = false )
             )
          ;  ( Zi = none, Zok = true )
        ),
        % Sign status
        ( rdf(R, traffic:requiresSign, Si)
          -> ( sign_matches(Si, S),
               ( present_sign(S) -> Sok = true ; Sok = false )
             )
          ;  ( Si = none, Sok = true )
        ),
        % Time window status
        ( rdf(R, traffic:appliesDuring, Ti)
          -> ( current_time(M),
               ( time_in_window(M, Ti) -> Tok = true ; Tok = false )
             )
          ;  ( Ti = none, Tok = true )
        ),
        % Category: generic vs scaffolds
        ( stop_sign_rule(R)  -> Category = stop_sign
        ; crosswalk_rule(R)  -> Category = crosswalk
        ; Category           = generic
        ),
        format(user_error,
               "Rule=~w | Cat=~w | Kind=~w | A=~w (~w) | Z=~w (~w) | S=~w (~w) | T=~w (~w)~n",
               [R, Category, AKind, Airi, Amatch, Zi, Zok, Si, Sok, Ti, Tok])
      )
    ).

% decide(+ActionCanonical, -Result, -Explanation)
%   Uses asserted scene facts plus RDF rules to classify the action
%   as legal or illegal and returns a short explanation string.
decide(ActionA, illegal, Why) :-
    illegal(ActionA, Rule),
    !,
    explain(illegal, Rule, Why).
decide(ActionA, legal,  Why)  :-
    ( dump_rules_for(ActionA) -> true ; true ),
    explain(legal,  _, Why).
