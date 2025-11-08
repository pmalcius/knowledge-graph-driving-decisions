# Knowledge-Graph Aided Driving Decisions

This project builds a symbolic reasoning system that determines whether a driver's action is legal or illegal based on traffic laws, context, and structured knowledge. It extends DSceneKG with traffic law rules and uses a Python rule engine for logical inference and explanations.

## Structure
- `ontology/`: RDF/OWL ontology extensions for traffic rules
- `src/`: Python scripts for parsing context, reasoning, and explanations
- `tests/`: JSON test cases and unit tests
- `docs/`: Documentation and weekly progress notes

## Week 1 Goal
Load DSceneKG and extend it with traffic law fields using `rdflib`.

### Acknowledgment

This project extends the **DSceneKG** knowledge graph described in:
Wickramarachchi, R., Henson, C., & Sheth, A. (2024). *A Benchmark Knowledge Graph of Driving Scenes for Knowledge Completion Tasks.* Proceedings of the 23rd International Semantic Web Conference (ISWC 2024).
