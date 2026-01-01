#!/usr/bin/env bash
# Discover CLI tools that support zsh completion generation
#
# Scans common installation directories and tests each tool
# for completion support using known patterns.
#
# Usage:
#   ./discover-completions.sh [--verbose]

set -euo pipefail

VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
  VERBOSE=true
fi

# Directories to scan
SCAN_DIRS=(
  "/opt/homebrew/bin"
  "/usr/local/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
)

# Known completion patterns to test
PATTERNS=(
  "completion zsh"
  "completions zsh"
  "complete zsh"
  "generate-completion zsh"
  "generate-shell-completion zsh"
  "gen-completions --shell zsh"
  "--completion zsh"
)

# Tools found with completion support
declare -A FOUND_TOOLS

# Test a tool for completion support
test_tool() {
  local tool="$1"
  local tool_path="$2"

  # Skip if not executable
  [[ -x "$tool_path" ]] || return

  # Test each pattern
  for pattern in "${PATTERNS[@]}"; do
    if timeout 1s "$tool_path" $pattern --help &>/dev/null; then
      FOUND_TOOLS["$tool"]="$pattern"
      return
    fi

    # Some tools output to stdout even without --help
    if timeout 1s "$tool_path" $pattern 2>&1 | head -1 | grep -qi "^#compdef\|^_.*function\|completion"; then
      FOUND_TOOLS["$tool"]="$pattern"
      return
    fi
  done

  # Check help output for "completion" mention
  if $VERBOSE; then
    if timeout 1s "$tool_path" --help 2>&1 | grep -qi "completion"; then
      echo "⚠️  $tool mentions 'completion' in help (manual check needed)"
    fi
  fi
}

echo "Scanning for tools with completion support..."
echo ""

# Collect all unique tools
declare -A ALL_TOOLS
for dir in "${SCAN_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue

  while IFS= read -r tool_path; do
    tool=$(basename "$tool_path")
    # Skip common noise
    [[ "$tool" =~ ^(cc|gcc|clang|python|node|ruby)$ ]] && continue
    ALL_TOOLS["$tool"]="$tool_path"
  done < <(find "$dir" -maxdepth 1 -type f -o -type l 2>/dev/null)
done

TOTAL=${#ALL_TOOLS[@]}
CURRENT=0

echo "Testing $TOTAL tools..."
if ! $VERBOSE; then
  echo "(Use --verbose to see tools mentioning completion in help)"
fi
echo ""

# Test each tool
for tool in "${!ALL_TOOLS[@]}"; do
  CURRENT=$((CURRENT + 1))
  if $VERBOSE; then
    printf "[%3d/%3d] Testing %s...\n" "$CURRENT" "$TOTAL" "$tool"
  fi
  test_tool "$tool" "${ALL_TOOLS[$tool]}"
done

# Report findings
echo ""
echo "=== Tools with Completion Support ==="
echo ""

if [[ ${#FOUND_TOOLS[@]} -eq 0 ]]; then
  echo "No tools found with completion support."
  echo "This might indicate:"
  echo "  - No supported tools installed"
  echo "  - Tools are in different directories"
  echo "  - Detection patterns need updating"
  exit 0
fi

printf "%-20s %s\n" "TOOL" "COMPLETION COMMAND"
printf "%-20s %s\n" "----" "-------------------"

for tool in $(echo "${!FOUND_TOOLS[@]}" | tr ' ' '\n' | sort); do
  printf "%-20s %s\n" "$tool" "${FOUND_TOOLS[$tool]}"
done

echo ""
echo "=== Generation Commands ==="
echo ""

BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || echo "/opt/homebrew")}"
TARGET_DIR="${BREW_PREFIX}/share/zsh/site-functions"

for tool in $(echo "${!FOUND_TOOLS[@]}" | tr ' ' '\n' | sort); do
  cmd="${FOUND_TOOLS[$tool]}"
  echo "$tool $cmd > $TARGET_DIR/_$tool"
done

echo ""
echo "Found ${#FOUND_TOOLS[@]} tools with completion support."
echo ""
echo "To generate all completions:"
echo "  See examples/generate-completions.sh"
