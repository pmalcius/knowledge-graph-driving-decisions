# src/decide.py
# Usage: python3 src/decide.py scenes/one.json

import json, sys, subprocess

# ================================
# Helper: Time parsing
# ================================
def hhmm_to_minutes(hhmm: str) -> int:
    h, m = hhmm.split(":")
    return int(h)*60 + int(m)

# ================================
# NEW: Scene Validator
# ================================
REQUIRED_KEYS = ["zone", "time", "action"]

def validate_scene(scene: dict):
    # Check for missing required keys
    missing = [k for k in REQUIRED_KEYS if k not in scene]
    if missing:
        raise ValueError(f"Scene is missing required field(s): {', '.join(missing)}")

    # zone must be a string
    if not isinstance(scene["zone"], str):
        raise TypeError("zone must be a string")

    # time must be HH:MM
    if not isinstance(scene["time"], str):
        raise TypeError("time must be a string in HH:MM format")

    parts = scene["time"].split(":")
    if len(parts) != 2:
        raise ValueError("time must be in HH:MM format")
    h, m = parts
    if not (h.isdigit() and m.isdigit()):
        raise ValueError("time must contain numeric HH and MM")

    # signs optional but must be a list of strings
    signs = scene.get("signs", [])
    if not isinstance(signs, list):
        raise TypeError("signs must be a list, if present")
    for s in signs:
        if not isinstance(s, str):
            raise TypeError("each sign must be a string")

# ================================
# Entry point / arg check
# ================================
if len(sys.argv) < 2:
    print("Usage: python3 src/decide.py <scene.json>", file=sys.stderr)
    sys.exit(1)

scene_path = sys.argv[1]
scene = json.load(open(scene_path))

# ================================
# NEW: Validate scene before use
# ================================
try:
    validate_scene(scene)
except Exception as e:
    print(f"Scene validation error: {e}", file=sys.stderr)
    sys.exit(1)

# ================================
# Pull scene fields
# ================================
zone   = scene["zone"]                  # e.g., "school_zone"
time_s = scene["time"]                  # e.g., "08:15"
signs  = scene.get("signs", [])         # e.g., ["no_turn_on_red"]
action = scene["action"]                # e.g., "right_on_red"

minutes = hhmm_to_minutes(time_s)

# ================================
# Build Prolog goal:
# 1) load reasoner
# 2) load KB
# 3) assert scene facts
# 4) call decide/3
# ================================
facts = [
    f"assertz(in_zone({zone}))",
    f"assertz(current_time({minutes}))",
    f"assertz(intended_action({action}))",
] + [f"assertz(present_sign({s}))" for s in signs]

goal = ",".join([
    "consult('reasoner/rdf_reasoner.pl')",
    "load_kb",
    *facts,
    f"decide({action}, R, Why), write(R), write('|'), write(Why), nl"
])

cmd = ["swipl", "-q", "-g", goal, "-t", "halt"]
proc = subprocess.run(cmd, capture_output=True, text=True)

# ================================
# Output handling
# ================================
if proc.stderr:
    print(proc.stderr, file=sys.stderr)

out = proc.stdout.strip()
if not out:
    print("No output from Prolog.", file=sys.stderr)
    sys.exit(2)

result, why = out.split("|", 1)

print(json.dumps({
    "zone": zone,
    "time": time_s,
    "signs": signs,
    "action": action,
    "result": result.upper(),  # LEGAL / ILLEGAL
    "explanation": why.strip()
}, indent=2))

