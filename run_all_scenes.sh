#!/usr/bin/env bash
set -e

echo "Running all traffic rule scenarios..."
echo

SCENES=(
  "illegal_school_right_on_red.json"
  "legal_outside_window.json"
  "school_zone_no_sign.json"
  "sandbox_generic_1.json"
  "sandbox_generic_2.json"
  "sandbox_generic_3.json"
  "stop_sign_basic.json"
  "stop_sign_scenario.json"
  "crosswalk_active_ped.json"
  "crosswalk_no_ped.json"
  "crosswalk_yield.json"
  "no_left_turn_illegal.json"
  "no_left_turn_ok.json"
)

for s in "${SCENES[@]}"; do
  echo "=============================="
  echo "Scene: $s"
  echo "------------------------------"
  python3 src/decide.py "scenes/$s"
  echo
done