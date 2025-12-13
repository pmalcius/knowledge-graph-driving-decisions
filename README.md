# Knowledge-Graph Aided Driving Decisions

This project builds a symbolic reasoning system that determines whether a driver's action is legal or illegal based on traffic laws, context, and structured knowledge. It extends DSceneKG with traffic law rules and uses a Python rule engine for logical inference and explanations.

## Requirements

- Operating System: macOS / Windows / Linux
- Python Version I used: Python 3.12
- Dependencies: Listed in `requirements.txt`

## Start Up

- Download the repositiory
- Download this: [file](https://drive.google.com/file/d/15pI4J3WYeoD4uBsbtUNIh51eegVThOAe/view) and put it into the ontology folder
- Create a Python virtual environment

```{text}
python -m venv venv
```

- Go into the Python venv

```{text}
source venv/bin/activate    # Mac/Linux
venv\Scripts\activate       # Windows I think???
```

- Install dependencies

```{text}
pip install -r requirements.txt
```

- Extend the DSceneKG-Pandaset.ttl and see if it passes the check

```{text}
python3 src/extend_ontology.py
python3 src/check_rule.py
```

- Finally you can run the tests by doing

```{text}
python3 src/decide.py scenes/<scene>.json
```

## Output

- Console output includes:
  - Final legality decision (LEGAL or ILLEGAL)
  - Triggered traffic rule(s)
  - Structured explanation of the reasoning process

## Structure

- `ontology/`: ontology extensions for traffic rules
- `reasoner/`: the rdf reasoner code
- `src/`: Python scripts for parsing context, reasoning, and explanations
- `scenes/`: JSON test cases and unit tests
- `docs/`: Documentation and weekly progress notes

### Acknowledgment

This project extends the **DSceneKG** knowledge graph described in:
Wickramarachchi, R., Henson, C., & Sheth, A. (2024). *A Benchmark Knowledge Graph of Driving Scenes for Knowledge Completion Tasks.* Proceedings of the 23rd International Semantic Web Conference (ISWC 2024).
