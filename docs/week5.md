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

- Completed the first fully functional non-time-based rule: Stop Sign behavior. A new Prolog predicate (stop_sign_violation/2) was added to classify movement at a Stop Sign as illegal unless a full stop action is satisfied. This introduces a second enforced traffic rule in addition to the School Zone / No Turn on Red rule.
- Integrated Stop Sign logic into the main decision workflow so that violations override generic rule evaluation and return a structured explanation through the same explanation template system.
- Updated the explanation pipeline so Stop Sign violations now generate rule-specific explanation text, including sign-matching status, inferred action violation, and clause-by-clause reasoning.
- Extended the debug output to clearly mark when the Stop Sign rule is triggered, making it easier to verify rule firing logic and match the output to expected behavior.
- Added new scene files (stop_sign_basic.json, stop_sign_scenario.json) to validate Stop Sign behavior under different contexts, confirming that:
- - movement with a Stop Sign present is classified as ILLEGAL
- - normal movement without a Stop Sign is correctly LEGAL
- With Stop Sign enforcement completed, the reasoning engine now supports multiple rule categories (time-window-based, sign-based, and zone-based rules), putting the system in its final shape before the full project write-up begins next week.
