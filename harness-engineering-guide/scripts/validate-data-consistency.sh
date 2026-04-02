#!/bin/bash
# Data Consistency Validation Script
# Validates that data files are internally consistent and reference valid IDs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data"

echo "=== Harness Engineering Guide - Data Validation ==="
echo ""

ERRORS=0

# ===== 1. Validate stages.json references valid item IDs =====
echo "[1/4] Validating stages.json active_items..."

for stage in bootstrap growth mature; do
  echo "  Checking stage: $stage"

  # Extract active_items for this stage
  active_items=$(jq -r ".stages.$stage.active_items[]" "$DATA_DIR/stages.json" 2>/dev/null || echo "")

  if [ -z "$active_items" ]; then
    echo "    ERROR: No active_items found for stage $stage"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check each item exists in checklist-items.json
  for item_id in $active_items; do
    # Strip carriage returns (Windows line endings)
    item_id=$(echo "$item_id" | tr -d '\r')
    exists=$(jq -r ".items[] | select(.id == \"$item_id\") | .id" "$DATA_DIR/checklist-items.json" 2>/dev/null | tr -d '\r')

    if [ -z "$exists" ]; then
      echo "    ERROR: Stage '$stage' references non-existent item '$item_id'"
      ERRORS=$((ERRORS + 1))
    fi
  done
done

if [ $ERRORS -eq 0 ]; then
  echo "  ✓ All stage references are valid"
fi
echo ""

# ===== 2. Validate profiles.json skip_items and critical_items =====
echo "[2/4] Validating profiles.json item references..."

profiles=$(jq -r '.profiles | keys[]' "$DATA_DIR/profiles.json" 2>/dev/null | tr -d '\r' || echo "")

for profile in $profiles; do
  echo "  Checking profile: $profile"

  # Check skip_items
  skip_items=$(jq -r ".profiles[\"$profile\"].skip_items[]?" "$DATA_DIR/profiles.json" 2>/dev/null | tr -d '\r' || echo "")
  for item_id in $skip_items; do
    exists=$(jq -r ".items[] | select(.id == \"$item_id\") | .id" "$DATA_DIR/checklist-items.json" 2>/dev/null | tr -d '\r')

    if [ -z "$exists" ]; then
      echo "    ERROR: Profile '$profile' skip_items references non-existent item '$item_id'"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check critical_items
  critical_items=$(jq -r ".profiles[\"$profile\"].critical_items[]?" "$DATA_DIR/profiles.json" 2>/dev/null | tr -d '\r' || echo "")
  for item_id in $critical_items; do
    exists=$(jq -r ".items[] | select(.id == \"$item_id\") | .id" "$DATA_DIR/checklist-items.json" 2>/dev/null | tr -d '\r')

    if [ -z "$exists" ]; then
      echo "    ERROR: Profile '$profile' critical_items references non-existent item '$item_id'"
      ERRORS=$((ERRORS + 1))
    fi
  done
done

if [ $ERRORS -eq 0 ]; then
  echo "  ✓ All profile references are valid"
fi
echo ""

# ===== 3. Validate profile weights sum to 1.0 =====
echo "[3/4] Validating profile weights sum to 1.0..."

for profile in $profiles; do
  # Calculate sum of weights
  weight_sum=$(jq -r ".profiles[\"$profile\"].weights | to_entries | map(.value) | add" "$DATA_DIR/profiles.json" 2>/dev/null | tr -d '\r')
  weight_sum=${weight_sum:-0}

  # Check if sum is approximately 1.0 (allow 0.001 tolerance for floating point)
  is_valid=$(echo "$weight_sum" | tr -d '\r' | awk '{if ($1 >= 0.999 && $1 <= 1.001) print "yes"; else print "no"}')

  if [ "$is_valid" = "no" ]; then
    echo "  ERROR: Profile '$profile' weights sum to $weight_sum (expected 1.0)"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -eq 0 ]; then
  echo "  ✓ All profile weights sum to 1.0"
fi
echo ""

# ===== 4. Validate Quick Audit has exactly 15 items =====
echo "[4/4] Validating Quick Audit item count..."

quick_count=$(jq -r '[.items[] | select(.quick_mode == true)] | length' "$DATA_DIR/checklist-items.json" 2>/dev/null | tr -d '\r' || echo "0")

if [ "$quick_count" -ne 15 ]; then
  echo "  ERROR: Quick Audit should have exactly 15 items, found $quick_count"
  ERRORS=$((ERRORS + 1))
else
  echo "  ✓ Quick Audit has exactly 15 items"
fi
echo ""

# ===== Summary =====
echo "=== Validation Summary ==="
if [ $ERRORS -eq 0 ]; then
  echo "✓ All validation checks passed"
  exit 0
else
  echo "✗ Found $ERRORS error(s)"
  exit 1
fi
