#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PLUGIN_DIR="/home/testuser/plugin"
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Test 1: Check plugin.json exists and is valid
info "Testing plugin.json..."
if [ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    if jq empty "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null; then
        # Check required fields
        NAME=$(jq -r '.name' "$PLUGIN_DIR/.claude-plugin/plugin.json")
        VERSION=$(jq -r '.version' "$PLUGIN_DIR/.claude-plugin/plugin.json")
        DESC=$(jq -r '.description' "$PLUGIN_DIR/.claude-plugin/plugin.json")

        if [ "$NAME" != "null" ] && [ "$VERSION" != "null" ] && [ "$DESC" != "null" ]; then
            pass "plugin.json has all required fields (name: $NAME, version: $VERSION)"
        else
            fail "plugin.json missing required fields"
        fi
    else
        fail "plugin.json is not valid JSON"
    fi
else
    fail "plugin.json not found at .claude-plugin/plugin.json"
fi

# Test 2: Check hooks configuration
info "Testing hooks configuration..."
if [ -f "$PLUGIN_DIR/hooks/hooks.json" ]; then
    if jq empty "$PLUGIN_DIR/hooks/hooks.json" 2>/dev/null; then
        pass "hooks.json is valid JSON"

        # Check that hooks have the expected structure
        HOOK_COUNT=$(jq '.hooks | length' "$PLUGIN_DIR/hooks/hooks.json")
        if [ "$HOOK_COUNT" -gt 0 ]; then
            pass "hooks.json contains $HOOK_COUNT hook type(s)"
        else
            fail "hooks.json contains no hooks"
        fi
    else
        fail "hooks.json is not valid JSON"
    fi
else
    fail "hooks/hooks.json not found"
fi

# Test 3: Check hook scripts are executable
info "Testing hook scripts..."
SCRIPT_DIR="$PLUGIN_DIR/hooks/scripts"
if [ -d "$SCRIPT_DIR" ]; then
    SCRIPT_COUNT=0
    NON_EXECUTABLE=0

    for script in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$script" ]; then
            ((SCRIPT_COUNT++))
            if [ -x "$script" ]; then
                pass "$(basename "$script") is executable"
            else
                fail "$(basename "$script") is not executable"
                ((NON_EXECUTABLE++))
            fi
        fi
    done

    if [ $SCRIPT_COUNT -eq 0 ]; then
        fail "No hook scripts found in hooks/scripts/"
    fi
else
    fail "hooks/scripts/ directory not found"
fi

# Test 4: Check skill structure
info "Testing skill structure..."
SKILL_FILE="$PLUGIN_DIR/skills/advanced-statusline/SKILL.md"
if [ -f "$SKILL_FILE" ]; then
    # Check for YAML frontmatter
    if head -1 "$SKILL_FILE" | grep -q "^---$"; then
        pass "SKILL.md has YAML frontmatter"

        # Extract and validate frontmatter fields
        if grep -q "^name:" "$SKILL_FILE" && grep -q "^description:" "$SKILL_FILE"; then
            SKILL_NAME=$(grep "^name:" "$SKILL_FILE" | head -1 | sed 's/^name:[[:space:]]*//')
            pass "SKILL.md has required frontmatter fields (name: $SKILL_NAME)"
        else
            fail "SKILL.md missing required frontmatter fields (name, description)"
        fi
    else
        fail "SKILL.md missing YAML frontmatter"
    fi
else
    fail "skills/advanced-statusline/SKILL.md not found"
fi

# Test 5: Check statusline script exists and is executable
info "Testing statusline script..."
STATUSLINE_SCRIPT="$PLUGIN_DIR/skills/advanced-statusline/scripts/statusline-wrapper.sh"
if [ -f "$STATUSLINE_SCRIPT" ]; then
    if [ -x "$STATUSLINE_SCRIPT" ]; then
        pass "statusline-wrapper.sh is executable"
    else
        fail "statusline-wrapper.sh is not executable"
    fi
else
    fail "statusline-wrapper.sh not found"
fi

# Test 6: Verify Claude Code can load the plugin
info "Testing Claude Code plugin loading..."
if command -v claude &> /dev/null; then
    pass "Claude Code CLI is installed"

    # Try to get version (basic sanity check)
    if claude --version &> /dev/null; then
        VERSION_OUTPUT=$(claude --version 2>&1)
        pass "Claude Code version: $VERSION_OUTPUT"
    else
        fail "Claude Code --version failed"
    fi

    # Note: We can't fully test --plugin-dir without an API key
    # But we can verify the command accepts the flag
    if claude --help 2>&1 | grep -q -- "--plugin-dir"; then
        pass "Claude Code supports --plugin-dir flag"
    else
        fail "Claude Code doesn't support --plugin-dir flag"
    fi
else
    fail "Claude Code CLI not found in PATH"
fi

# Test 7: Check required dependencies
info "Testing dependencies..."
if command -v jq &> /dev/null; then
    pass "jq is installed"
else
    fail "jq is not installed"
fi

if command -v starship &> /dev/null; then
    pass "starship is installed"
else
    fail "starship is not installed"
fi

# Test 8: Statusline execution test
info "Testing statusline execution..."

# Create mock project directory with git repo
MOCK_PROJECT="/home/testuser/mock-project"
mkdir -p "$MOCK_PROJECT"
cd "$MOCK_PROJECT"
git init --quiet 2>/dev/null
git config user.email "test@test.com"
git config user.name "Test User"
echo "# Test Project" > README.md
git add README.md
git commit -m "Initial commit" --quiet 2>/dev/null

# Create mock session cache files
TEST_SESSION_ID="test-session-abc123"
echo "Test Session Name" > "/tmp/claude-session-name-${TEST_SESSION_ID}.txt"
echo "Testing plugin installation" > "/tmp/claude-session-summary-${TEST_SESSION_ID}.txt"
echo "Read, Write, Edit" > "/tmp/claude-assistant-summary-${TEST_SESSION_ID}.txt"
echo "test-plan" > "/tmp/claude-session-plan-${TEST_SESSION_ID}.txt"

# Create mock input JSON
MOCK_INPUT=$(cat <<EOF
{
  "workspace": { "current_dir": "$MOCK_PROJECT" },
  "model": { "display_name": "Claude 3.5 Sonnet" },
  "session_id": "$TEST_SESSION_ID",
  "session_name": "Fallback Name",
  "context_window": {
    "current_usage": { "input_tokens": 5000, "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0 },
    "context_window_size": 200000
  }
}
EOF
)

# Run statusline script
cd "$MOCK_PROJECT"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
output=$(echo "$MOCK_INPUT" | bash "$PLUGIN_DIR/skills/advanced-statusline/scripts/statusline-wrapper.sh" 2>&1)
exit_code=$?

# Verify exit code
if [ $exit_code -eq 0 ]; then
    pass "Statusline script executed successfully"
else
    fail "Statusline script failed with exit code $exit_code"
fi

# Count output lines (should be 3)
line_count=$(echo "$output" | wc -l | tr -d ' ')
if [ "$line_count" -eq 3 ]; then
    pass "Statusline output has 3 lines"
else
    fail "Expected 3 lines, got $line_count"
fi

# Verify line 1: emoji, model, starship, context
line1=$(echo "$output" | head -1)
if echo "$line1" | grep -q "Claude 3.5 Sonnet"; then
    pass "Line 1 contains model name"
else
    fail "Line 1 missing model name"
fi

if echo "$line1" | grep -q "% ctx"; then
    pass "Line 1 contains context percentage"
else
    fail "Line 1 missing context percentage"
fi

# Verify line 2: summary, tools, session ID
line2=$(echo "$output" | head -2 | tail -1)
if echo "$line2" | grep -q "$TEST_SESSION_ID"; then
    pass "Line 2 contains session ID"
else
    fail "Line 2 missing session ID"
fi

if echo "$line2" | grep -q "🔧"; then
    pass "Line 2 contains tool indicator"
else
    fail "Line 2 missing tool indicator"
fi

# Verify line 3: session name, plan
line3=$(echo "$output" | tail -1)
if echo "$line3" | grep -q "Test Session Name"; then
    pass "Line 3 contains session name from cache"
else
    fail "Line 3 missing cached session name"
fi

if echo "$line3" | grep -q "📋"; then
    pass "Line 3 contains plan indicator"
else
    fail "Line 3 missing plan indicator"
fi

# Print full output for debugging
echo ""
info "Statusline output:"
echo "$output"
echo ""

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
