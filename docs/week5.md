# Week 5 Check-In

## How to run

If it is your first time running it

```{text}
python3 src/extend_ontology.py
python3 src/check_rule.py
```

To run the tests

```{text}
python3 src/decide.py scenes/<scene>.json
```

The new tests:

```{text}
python3 src/decide.py scenes/stop_sign_basic.json
python3 src/decide.py scenes/stop_sign_scenario.json
```

## Check-in

Hours worked: 9 hours

- Completed the first fully functional non time based rule: Stop Sign behavior. A new Prolog predicate (stop_sign_violation/2) was added to classify movement at a Stop Sign as illegal unless a full stop action is satisfied. This introduces a second enforced traffic rule in addition to the School Zone / No Turn on Red rule.
- Integrated Stop Sign logic into the main decision workflow so that violations override generic rule evaluation and return a structured explanation through the same explanation template system.
- Updated the explanation pipeline so Stop Sign violations now generate rule specific explanation text, including sign matching status, inferred action violation, and clause by clause reasoning.
- Extended the debug output to clearly mark when the Stop Sign rule is triggered, making it easier to verify rule firing logic and match the output to expected behavior.
- Added new scene files (stop_sign_basic.json, stop_sign_scenario.json) to validate Stop Sign behavior under different contexts, confirming that:
  - movement with a Stop Sign present is classified as ILLEGAL
  - normal movement without a Stop Sign is correctly LEGAL
- With Stop Sign enforcement completed, the reasoning engine now supports multiple rule categories (time window based, sign based, and zone based rules), putting the system in its final shape before the full project write up begins.
- Added a third enforced rule type: a No Left Turn rule, modeled as a TrafficRule in the ontology that connects a NoLeftTurn sign to a LeftTurn driver action. This shows that the pattern generalizes beyond right_on_red to different movements.
- Extended the ontology with new individuals for NoLeftTurn and LeftTurn, defined as traffic:Sign and traffic:DriverAction, while still subclassing signs under driving:RoadSign from the original DSceneKG graph so the extension really sits on top of the provided ontology.
- Updated the Prolog reasoner mapping so left_turn is treated as a canonical action, letting the same generic rule_applies/3 logic catch No Left Turn violations.
- Added two new test scenes, no_left_turn_illegal.json and no_left_turn_ok.json, to demonstrate that:
  - left_turn with a NoLeftTurn sign present is classified as ILLEGAL
  - the same left_turn with no sign present is correctly classified as LEGAL
- Collected all scenarios into a single regression script (run_all_scenes.sh) that runs the full suite of JSON scenes in one command and prints each case with a header and explanation. This makes it easier to demo the system and quickly confirm that all rules still behave as expected after changes.
- Expanded the overall scene set (school_zone_no_sign.json, crosswalk_active_ped.json, crosswalk_no_ped.json, crosswalk_yield.json, plus the left turn scenes). Together they show how the engine handles differences in time windows, sign presence, and zones, and how the explanations change when different parts of a rule match or fail.
