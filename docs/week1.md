# Week 1 Check-in

## How to run

```{text}
python3 src/extend_ontology.py
python3 src/rule_check.py
```

To test the resoner

```{text}
python3 src/decide.py scenes/illegal_school_right_on_red.json        
python3 src/decide.py scenes/legal_outside_window.json
```

## Check-in

Hours worked: 5 hours

Progress:

- Set up the project repository, virtual environment, and initial directory structure (ontology/, reasoner/, src/, scenes/).
- Loaded the DSceneKG-Pandaset.ttl ontology and wrote a Python extension script to generate a companion ontology (dscenekg_extended.ttl) with a custom traffic: namespace.
- Added classes (TrafficRule, Zone, Sign, TimeWindow, DriverAction) and object/datatype properties needed to express traffic constraints.
- Created individuals for SchoolZone, NoTurnOnRed, RightOnRed, and the DropOff_0730_0900 time window.
- Added the first rule to the ontology: No Right on Red in a School Zone during 07:30–09:00 when a “No Turn on Red” sign is present.
- Implemented a SWI-Prolog reasoner that loads both ontologies and evaluates scene facts (zone, time, signs, action) against rule conditions.
- Completed an end-to-end test pipeline (JSON → Python → Prolog → result) showing correct behavior for both an illegal case (08:15) and a legal case (10:30).
