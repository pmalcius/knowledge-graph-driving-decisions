# Week 2 Check-in

## How to run

This is how you run some of the stuff that we did this week

```{text}
python3 src/decide.py scenes/illegal_school_right_on_red.json
python3 src/decide.py scenes/legal_outside_window.json
```

## Check-in

Hours worked: 5 hours

Progress:

- Reviewed and cleaned up the ontology extension created in Week 1, ensuring all custom classes (TrafficRule, Zone, Sign, TimeWindow, DriverAction) and properties were correctly defined and consistently namespaced.
- Added new individuals for additional traffic elements, including a generic CrosswalkZone, a StopSign, and a YieldSign to prepare for building more complex driving rules.
- Drafted two new rule outlines in the ontology:
(1) Yield to Pedestrians at a Crosswalk.
(2) Stop Required at Stop Sign Before Proceeding.
These have placeholder individuals and properties ready for refinement next week.
- Updated the Python preprocessing script to better structure how scene data (zone, time, signage, actions) is converted into RDF triples before being passed to the Prolog reasoner.
- Ran small SPARQL sanity checks to verify the new individuals and properties load correctly and link to the proper parent classes.
- Reviewed the SWI-Prolog predicates for rule checking and added comments to clarify how time windows, zone membership, and action evaluation will be handled when new rules are added.
