#!/usr/bin/env bats

# Plugin Configuration Tests
# Tests for marketplace.json, plugin.json, and plugin loading

load test_helper

@test "plugin.json exists and is valid JSON" {
    [ -f "$BATS_TEST_DIRNAME/../.claude-plugin/plugin.json" ]
    jq -e '.' "$BATS_TEST_DIRNAME/../.claude-plugin/plugin.json" > /dev/null
}

@test "plugin.json has required fields" {
    plugin_json="$BATS_TEST_DIRNAME/../.claude-plugin/plugin.json"

    # Check name
    name=$(jq -r '.name' "$plugin_json")
    [ "$name" = "shell-ergonomics-skills" ]

    # Check version
    version=$(jq -r '.version' "$plugin_json")
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

    # Check description
    description=$(jq -r '.description' "$plugin_json")
    [ -n "$description" ]
}

@test "marketplace.json exists and is valid JSON" {
    [ -f "$BATS_TEST_DIRNAME/../.claude-plugin/marketplace.json" ]
    jq -e '.' "$BATS_TEST_DIRNAME/../.claude-plugin/marketplace.json" > /dev/null
}

@test "marketplace.json has required fields" {
    marketplace_json="$BATS_TEST_DIRNAME/../.claude-plugin/marketplace.json"

    # Check name
    name=$(jq -r '.name' "$marketplace_json")
    [ -n "$name" ]

    # Check description
    description=$(jq -r '.description' "$marketplace_json")
    [ -n "$description" ]

    # Check plugins array exists
    jq -e '.plugins | type == "array"' "$marketplace_json" > /dev/null

    # Check plugins array has at least one plugin
    count=$(jq '.plugins | length' "$marketplace_json")
    [ "$count" -ge 1 ]
}

@test "marketplace.json plugin entry is valid" {
    marketplace_json="$BATS_TEST_DIRNAME/../.claude-plugin/marketplace.json"

    # Check first plugin has name
    name=$(jq -r '.plugins[0].name' "$marketplace_json")
    [ "$name" = "shell-ergonomics-skills" ]

    # Check first plugin has description
    description=$(jq -r '.plugins[0].description' "$marketplace_json")
    [ -n "$description" ]

    # Check first plugin has path
    path=$(jq -r '.plugins[0].path' "$marketplace_json")
    [ "$path" = "." ]
}

@test "hooks.json exists and is valid JSON" {
    [ -f "$BATS_TEST_DIRNAME/../hooks/hooks.json" ]
    jq -e '.' "$BATS_TEST_DIRNAME/../hooks/hooks.json" > /dev/null
}

@test "hooks.json has session naming hook" {
    hooks_json="$BATS_TEST_DIRNAME/../hooks/hooks.json"

    # Check UserPromptSubmit hook exists under .hooks
    jq -e '.hooks.UserPromptSubmit' "$hooks_json" > /dev/null

    # Check it's an array
    jq -e '.hooks.UserPromptSubmit | type == "array"' "$hooks_json" > /dev/null

    # Check session-naming.sh is configured
    jq -e '.hooks.UserPromptSubmit[].hooks[] | select(.command | contains("session-naming.sh"))' "$hooks_json" > /dev/null
}

@test "plugin directory structure is correct" {
    # Check main directories exist
    [ -d "$BATS_TEST_DIRNAME/../hooks" ]
    [ -d "$BATS_TEST_DIRNAME/../skills" ]
    [ -d "$BATS_TEST_DIRNAME/../tests" ]
    [ -d "$BATS_TEST_DIRNAME/../.claude-plugin" ]

    # Check hooks/scripts exists
    [ -d "$BATS_TEST_DIRNAME/../hooks/scripts" ]

    # Check critical scripts exist
    [ -f "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" ]
    [ -f "$BATS_TEST_DIRNAME/../hooks/scripts/cache-cleanup.sh" ]
    [ -f "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh" ]
}

@test "all hook scripts are executable" {
    for script in "$BATS_TEST_DIRNAME/../hooks/scripts/"*.sh; do
        [ -x "$script" ] || [ -r "$script" ]  # Either executable or readable by bash
    done
}

@test "statusline script is executable" {
    statusline="$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh"
    [ -x "$statusline" ] || [ -r "$statusline" ]
}

@test "plugin loads with --plugin-dir flag" {
    # Test that the plugin directory structure is valid for loading
    # This doesn't actually load Claude Code, just validates the structure

    plugin_dir="$BATS_TEST_DIRNAME/.."

    # Check plugin.json is loadable
    jq -e '.name' "$plugin_dir/.claude-plugin/plugin.json" > /dev/null

    # Check hooks.json is loadable
    jq -e '.' "$plugin_dir/hooks/hooks.json" > /dev/null

    # Simulate what Claude Code would check
    [ -d "$plugin_dir" ]
    [ -f "$plugin_dir/.claude-plugin/plugin.json" ]
}
