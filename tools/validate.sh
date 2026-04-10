#!/usr/bin/env bash
set -euo pipefail

# MioIsland Plugin Validator
# Usage: ./tools/validate.sh <plugin-directory>

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
  echo -e "  ${GREEN}PASS${NC} $1"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "  ${RED}FAIL${NC} $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo -e "  ${YELLOW}WARN${NC} $1"
}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <plugin-directory>"
  exit 1
fi

PLUGIN_DIR="$1"
PLUGIN_JSON="$PLUGIN_DIR/plugin.json"

echo "Validating plugin in: $PLUGIN_DIR"
echo ""

# Check plugin.json exists
if [ ! -f "$PLUGIN_JSON" ]; then
  fail "plugin.json not found"
  echo ""
  echo -e "${RED}FAIL${NC} - plugin.json is missing"
  exit 1
fi
pass "plugin.json exists"

# Validate JSON syntax
if python3 -m json.tool "$PLUGIN_JSON" > /dev/null 2>&1; then
  pass "Valid JSON syntax"
else
  fail "Invalid JSON syntax"
  echo ""
  echo -e "${RED}FAIL${NC} - Fix JSON syntax errors first"
  exit 1
fi

# Read JSON fields using python3
read_field() {
  python3 -c "
import json, sys
with open('$PLUGIN_JSON') as f:
    data = json.load(f)
keys = '$1'.split('.')
val = data
for k in keys:
    if isinstance(val, dict) and k in val:
        val = val[k]
    else:
        sys.exit(1)
print(val)
" 2>/dev/null
}

has_field() {
  python3 -c "
import json, sys
with open('$PLUGIN_JSON') as f:
    data = json.load(f)
keys = '$1'.split('.')
val = data
for k in keys:
    if isinstance(val, dict) and k in val:
        val = val[k]
    else:
        sys.exit(1)
" 2>/dev/null
}

# Check required common fields
REQUIRED_FIELDS="type id name version author description tags preview"
for field in $REQUIRED_FIELDS; do
  if has_field "$field"; then
    pass "Field '$field' present"
  else
    fail "Missing required field '$field'"
  fi
done

# Check author.name
if has_field "author.name"; then
  pass "Field 'author.name' present"
else
  fail "Missing required field 'author.name'"
fi

# Check preview file exists
PREVIEW=$(read_field "preview" 2>/dev/null || echo "")
if [ -n "$PREVIEW" ] && [ -f "$PLUGIN_DIR/$PREVIEW" ]; then
  pass "Preview file '$PREVIEW' exists"
else
  warn "Preview file '$PREVIEW' not found (add before submitting)"
fi

# Get plugin type
TYPE=$(read_field "type" 2>/dev/null || echo "unknown")
echo ""
echo "Plugin type: $TYPE"

# Type-specific validation
case "$TYPE" in
  theme)
    echo "Running theme validation..."
    HEX_PATTERN='^#[0-9A-Fa-f]{6}$'

    for color_field in bg fg secondaryFg; do
      COLOR=$(read_field "palette.$color_field" 2>/dev/null || echo "")
      if [ -z "$COLOR" ]; then
        fail "Missing palette.$color_field"
      elif echo "$COLOR" | grep -qE "$HEX_PATTERN"; then
        pass "palette.$color_field is valid hex ($COLOR)"
      else
        fail "palette.$color_field is not valid 6-digit hex ($COLOR)"
      fi
    done
    ;;

  buddy)
    echo "Running buddy validation..."
    STATES="idle working needsYou thinking error done"

    for state in $STATES; do
      if has_field "animations.$state"; then
        pass "Animation state '$state' present"
      else
        fail "Missing animation state '$state'"
      fi
    done

    # Check palette size
    PALETTE_SIZE=$(python3 -c "
import json
with open('$PLUGIN_JSON') as f:
    data = json.load(f)
print(len(data.get('palette', [])))
" 2>/dev/null || echo "0")

    if [ "$PALETTE_SIZE" -le 8 ]; then
      pass "Palette size ($PALETTE_SIZE) <= 8"
    else
      fail "Palette size ($PALETTE_SIZE) exceeds maximum of 8"
    fi

    # Check grid dimensions
    WIDTH=$(read_field "grid.width" 2>/dev/null || echo "0")
    HEIGHT=$(read_field "grid.height" 2>/dev/null || echo "0")
    if [ "$WIDTH" = "13" ] && [ "$HEIGHT" = "11" ]; then
      pass "Grid dimensions 13x11"
    else
      fail "Grid must be 13x11, got ${WIDTH}x${HEIGHT}"
    fi
    ;;

  sound)
    echo "Running sound validation..."
    if has_field "category"; then
      CATEGORY=$(read_field "category" 2>/dev/null || echo "")
      if echo "$CATEGORY" | grep -qE "^(music|notification|ambient)$"; then
        pass "Category '$CATEGORY' is valid"
      else
        fail "Invalid category '$CATEGORY' (must be music, notification, or ambient)"
      fi
    else
      fail "Missing required field 'category'"
    fi

    if has_field "sounds"; then
      pass "Field 'sounds' present"
    else
      fail "Missing required field 'sounds'"
    fi
    ;;

  *)
    fail "Unknown plugin type '$TYPE' (must be theme, buddy, or sound)"
    ;;
esac

# Summary
echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}FAIL${NC}"
  exit 1
else
  echo -e "${GREEN}PASS${NC}"
  exit 0
fi
