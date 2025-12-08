from rdflib import Graph, Namespace, RDF, RDFS, XSD, Literal

BASE = "ontology/DSceneKG-Pandaset.ttl"

# Load base graph (DSceneKG)
g = Graph()
g.parse(BASE, format="turtle")
print(f"[load] DSceneKG triples: {len(g)}")

# Bind existing DSceneKG namespaces (match what you saw in the file)
DRIVING = Namespace("http://purl.net/dscene-kg/drivingscene/v02/")
SCENE   = Namespace("http://purl.net/dscene-kg/scene/v02/")
g.bind("driving", DRIVING)
g.bind("scene", SCENE)

# Your extension namespace
TRAFFIC = Namespace("https://github.com/pmalcius/knowledge-graph-driving-decisions/traffic#")
g.bind("traffic", TRAFFIC)

# ---- Classes (reuse/subclass where possible) ----
# Keep your TrafficRule as new; reuse their RoadSign via subclassing
g.add((TRAFFIC.TrafficRule, RDF.type, RDFS.Class))
g.add((TRAFFIC.Sign, RDF.type, RDFS.Class))
g.add((TRAFFIC.Sign, RDFS.subClassOf, DRIVING.RoadSign))

# If DSceneKG already defines zones, use those; if not, keep a Zone class you own
g.add((TRAFFIC.Zone, RDF.type, RDFS.Class))
g.add((TRAFFIC.TimeWindow, RDF.type, RDFS.Class))
g.add((TRAFFIC.DriverAction, RDF.type, RDFS.Class))

# ---- Object properties ----
def add_obj_prop(p, dom, rng):
    g.add((p, RDF.type, RDF.Property))
    g.add((p, RDFS.domain, dom))
    g.add((p, RDFS.range, rng))

add_obj_prop(TRAFFIC.appliesInZone, TRAFFIC.TrafficRule, TRAFFIC.Zone)
add_obj_prop(TRAFFIC.appliesDuring, TRAFFIC.TrafficRule, TRAFFIC.TimeWindow)
add_obj_prop(TRAFFIC.requiresSign,  TRAFFIC.TrafficRule, TRAFFIC.Sign)
add_obj_prop(TRAFFIC.permitsAction, TRAFFIC.TrafficRule, TRAFFIC.DriverAction)
add_obj_prop(TRAFFIC.prohibitsAction, TRAFFIC.TrafficRule, TRAFFIC.DriverAction)

# ---- Datatype properties for time window (simple, Week-1 friendly) ----
for dp in ("startsAtTime", "endsAtTime"):
    g.add((TRAFFIC[dp], RDF.type, RDF.Property))
    g.add((TRAFFIC[dp], RDFS.domain, TRAFFIC.TimeWindow))
    g.add((TRAFFIC[dp], RDFS.range, XSD.time))

# ---- Seed individuals that REUSE their world where sensible ----
# Sign individual as a specialized road sign
no_turn_on_red_sign = TRAFFIC.NoTurnOnRed
g.add((no_turn_on_red_sign, RDF.type, TRAFFIC.Sign))
g.add((no_turn_on_red_sign, RDFS.label, Literal("No Turn on Red")))

# Zone (keep yours unless you later discover a DSceneKG zone class to reuse)
school_zone = TRAFFIC.SchoolZone
g.add((school_zone, RDF.type, TRAFFIC.Zone))
g.add((school_zone, RDFS.label, Literal("School Zone")))

# Driver action vocabulary
right_on_red = TRAFFIC.RightOnRed
g.add((right_on_red, RDF.type, TRAFFIC.DriverAction))

# TimeWindow with explicit start/end times
drop_window = TRAFFIC.DropOff_0730_0900
g.add((drop_window, RDF.type, TRAFFIC.TimeWindow))
g.add((drop_window, TRAFFIC.startsAtTime, Literal("07:30:00", datatype=XSD.time)))
g.add((drop_window, TRAFFIC.endsAtTime,   Literal("09:00:00", datatype=XSD.time)))

# Additional Week 2 individuals

# Generic crosswalk zone
crosswalk_zone = TRAFFIC.CrosswalkZone
g.add((crosswalk_zone, RDF.type, TRAFFIC.Zone))
g.add((crosswalk_zone, RDFS.label, Literal("Crosswalk Zone")))

# Stop sign and yield sign as specific traffic:Sign individuals
stop_sign = TRAFFIC.StopSign
g.add((stop_sign, RDF.type, TRAFFIC.Sign))
g.add((stop_sign, RDFS.label, Literal("Stop Sign")))

# Extra comments for explanation / readability
g.add((crosswalk_zone, RDFS.comment,
       Literal("Zone representing a pedestrian crosswalk where vehicles may need to yield.")))

g.add((stop_sign, RDFS.comment,
       Literal("Road sign indicating vehicles must come to a complete stop before proceeding.")))

yield_sign = TRAFFIC.YieldSign
g.add((yield_sign, RDF.type, TRAFFIC.Sign))
g.add((yield_sign, RDFS.label, Literal("Yield Sign")))


# Example rule: prohibit RightOnRed in School Zone during drop-off if sign present
rule = TRAFFIC.Rule_NoTurnOnRed_SchoolDrop
g.add((rule, RDF.type, TRAFFIC.TrafficRule))
g.add((rule, TRAFFIC.appliesInZone, school_zone))
g.add((rule, TRAFFIC.appliesDuring, drop_window))
g.add((rule, TRAFFIC.requiresSign,  no_turn_on_red_sign))
g.add((rule, TRAFFIC.prohibitsAction, right_on_red))
g.add((rule, RDFS.comment, Literal(
    "No Right on Red in School Zone during 07:30-09:00 when 'No Turn on Red' sign is present."
)))

# Placeholder rule: Yield to pedestrians at crosswalk
yield_rule = TRAFFIC.Rule_YieldAtCrosswalk
g.add((yield_rule, RDF.type, TRAFFIC.TrafficRule))
g.add((yield_rule, TRAFFIC.appliesInZone, crosswalk_zone))
g.add((yield_rule, RDFS.comment, Literal(
    "Placeholder: vehicles must yield to pedestrians when in a Crosswalk Zone."
)))

# Placeholder rule: Stop at stop sign before proceeding
stop_rule = TRAFFIC.Rule_StopAtStopSign
g.add((stop_rule, RDF.type, TRAFFIC.TrafficRule))
g.add((stop_rule, TRAFFIC.requiresSign, stop_sign))
g.add((stop_rule, RDFS.comment, Literal(
    "Placeholder: vehicles must come to a complete stop at a Stop Sign before proceeding."
)))

# Serialize your extension
out_path = "ontology/dscenekg_extended.ttl"
g.serialize(out_path, format="turtle")
print(f"[save] wrote {out_path}")