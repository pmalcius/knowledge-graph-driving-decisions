# Week 3 Check-In

## How to run

Some generic tests for our implementation

```{text}
python3 src/decide.py scenes/sandbox_generic_1.json   
python3 src/decide.py scenes/sandbox_generic_2.json
python3 src/decide.py scenes/sandbox_generic_3.json
```

## Check-in

Hours worked: 4 hours

Progress:

- Reviewed the Prolog rule templates and reorganized the predicates to make it easier to plug in future rules like crosswalk behavior and stop-sign logic. Added small comments and standardized naming conventions.
- Added a lightweight “scene validator” step to the Python preprocessing script that checks for missing fields (e.g., missing zone, missing action, or undefined time format) before converting scene data to RDF triples.
- Wrote a small sandbox JSON file with 3 simple test scenes (generic zone + action combos) to sanity-test the validator and preprocessing pipeline.
- Began outlining how the new rules (Yield at Crosswalk, Stop Before Proceeding) will be integrated into the Prolog reasoner next week