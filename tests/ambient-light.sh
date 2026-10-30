#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STATE_DIR=$(mktemp -d)
ALS="$STATE_DIR/lux"
trap 'rm -f "$STATE_DIR/lux" "$STATE_DIR/dark"; rmdir "$STATE_DIR"' EXIT

# Load just the sensor policy without probing or changing real hardware.
source <(sed -n '/^update_dark() {$/,/^}$/p' "$ROOT/bin/omarchy-keyboard-backlight")

DARK_LUX=40
BRIGHT_LUX=80

while read -r lux initial expected; do
  printf '%s\n' "$lux" > "$ALS"
  dark=$initial
  update_dark
  if [[ $dark != "$expected" || $(cat "$STATE_DIR/dark") != "$expected" ]]; then
    printf 'FAIL: lux=%s initial=%s expected=%s actual=%s\n' "$lux" "$initial" "$expected" "$dark" >&2
    exit 1
  fi
done <<'CASES'
0.824539 0 1
80.5 1 0
80.0 1 1
40.0 0 0
39.5 0 1
60.5 0 0
60.5 1 1
0 0 1
100 1 0
CASES

printf 'Ambient light threshold checks passed.\n'
