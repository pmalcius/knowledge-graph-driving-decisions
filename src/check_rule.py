from rdflib import Graph, Namespace

g = Graph()
g.parse("ontology/dscenekg_extended.ttl", format="turtle")

TRAFFIC = Namespace("https://github.com/pmalcius/knowledge-graph-driving-decisions/traffic#")

# 1) ASK: did the rule get created and linked correctly?
ask_q = """
PREFIX traffic: <https://github.com/pmalcius/knowledge-graph-driving-decisions/traffic#>
ASK {
  traffic:Rule_NoTurnOnRed_SchoolDrop a traffic:TrafficRule ;
    traffic:prohibitsAction traffic:RightOnRed ;
    traffic:appliesInZone traffic:SchoolZone ;
    traffic:appliesDuring traffic:DropOff_0730_0900 ;
    traffic:requiresSign traffic:NoTurnOnRed .
}
"""
print("Rule triple pattern present? ->", bool(g.query(ask_q)))

# 2) SELECT: list all TrafficRule instances and their key links
select_q = """
PREFIX traffic: <https://github.com/pmalcius/knowledge-graph-driving-decisions/traffic#>
SELECT ?rule ?zone ?action ?tw ?sign WHERE {
  ?rule a traffic:TrafficRule .
  OPTIONAL { ?rule traffic:appliesInZone ?zone . }
  OPTIONAL { ?rule traffic:prohibitsAction ?action . }
  OPTIONAL { ?rule traffic:appliesDuring ?tw . }
  OPTIONAL { ?rule traffic:requiresSign ?sign . }
}
"""
for row in g.query(select_q):
    print("RULE:", row.rule)
    if row.zone:   print("  zone:   ", row.zone)
    if row.action: print("  action: ", row.action)
    if row.tw:     print("  time:   ", row.tw)
    if row.sign:   print("  sign:   ", row.sign)