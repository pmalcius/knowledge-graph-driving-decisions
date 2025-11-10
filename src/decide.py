# src/decide.py
# Usage: python3 src/decide.py scenes/one.json
import json, sys, subprocess

def hhmm_to_minutes(hhmm: str) -> int:
    h, m = hhmm.split(":")
    return int(h)*60 + int(m)

if len(sys.argv) < 2:
    print("Usage: python3 src/decide.py <scene.json>", file=sys.stderr)
    sys.exit(1)

scene_path = sys.argv[1]
scene = json.load(open(scene_path))

zone   = scene["zone"]                  # e.g., "school_zone"
time_s = scene["time"]                  # e.g., "08:15"
signs  = scene.get("signs", [])         # e.g., ["no_turn_on_red"]
action = scene["action"]                # e.g., "right_on_red"

minutes = hhmm_to_minutes(time_s)

# Build a Prolog goal to:
#  1) consult the reasoner
#  2) load TTL KB
#  3) assert scene facts
#  4) call decide/3 and print "RESULT|WHY"
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
