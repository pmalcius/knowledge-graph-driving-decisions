# Week 4 Check-In

## How to run

If it is your first time running it

```{text}
python3 src/extend_ontology.py
python3 src/check_rule.py
```

To run the tests

```{text}
python3 src/decide.py scenes/illegal_school_right_on_red.json
python3 src/decide.py scenes/legal_outside_window.json
python3 src/decide.py scenes/sandbox_generic_1.json
python3 src/decide.py scenes/sandbox_generic_2.json
python3 src/decide.py scenes/sandbox_generic_3.json
python3 src/decide.py scenes/stop_sign_basic.json
python3 src/decide.py scenes/crosswalk_yield.json

```

## Check-in

Hours worked: 5 hours

Progress:

- Implemented partial rule logic for Stop Sign behavior in the Prolog reasoner. Added a new predicate structure (must_stop_before_proceeding/1) and began integrating it with the existing rule_applies/3 pattern so that stop sign logic can be evaluated similarly to right-on-red rules.
- Added provisional crosswalk rule scaffolding in Prolog, including an outline for checking pedestrian presence and zone membership. These rules are not fully enforced yet, but the template and control flow are in place for expansion next week.
- Extended the scene validator in decide.py to support additional optional fields (like "pedestrians_present" or "speed"), ensuring the pipeline won’t crash when new fields are introduced for future rules.
- Created two new test scenes (crosswalk_yield.json, stop_sign_basic.json) to begin testing how scene data will interface with the forthcoming rules. Verified that these scenes pass validation and correctly round-trip through the Prolog pipeline even though their rules are not fully enforced yet.
- Refactored portions of rdf_reasoner.pl to better separate rule categories (school-zone rules, stop-sign rules, crosswalk rules). Added block-level comments to clearly mark each rule group, making the code easier to navigate as more rules are added.
