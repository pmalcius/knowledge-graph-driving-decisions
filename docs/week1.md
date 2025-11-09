# Week 1 Check-in

## How to run

```{text}
python3 src/extend_ontology.py
```

```{text}
python3 src/rule_check.py
```

## Check-in

Hours worked: 5 hours

Progress:

- Set up the project repository and virtual environment.
- Loaded the DSceneKG-Pandaset.ttl ontology and wrote a Python script to extend it with a custom traffic: namespace.
- Added classes (TrafficRule, Zone, Sign, TimeWindow, DriverAction) and properties needed for reasoning about driving legality.
- Created and verified the first traffic rule (No Turn on Red in a School Zone during 07:30–09:00) using SPARQL, confirming the extension works correctly.
