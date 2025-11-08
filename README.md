# Knowledge-Graph Aided Driving Decisions

This project builds a symbolic reasoning system that determines whether a driver's action is legal or illegal based on traffic laws, context, and structured knowledge. It extends DSceneKG with traffic law rules and uses a Python rule engine for logical inference and explanations.

## Structure
- `ontology/`: RDF/OWL ontology extensions for traffic rules
- `src/`: Python scripts for parsing context, reasoning, and explanations
- `tests/`: JSON test cases and unit tests
- `docs/`: Documentation and weekly progress notes

## Week 1 Goal
Load DSceneKG and extend it with traffic law fields using `rdflib`.
