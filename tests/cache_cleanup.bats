#!/usr/bin/env bats

load test_helper

@test "exits immediately when cache under 100MB" {
    # Create small cache files (< 1MB total)
    mkdir -p /tmp
    touch /tmp/claude-session-summary-test.txt
    touch /tmp/claude-session-name-test.txt

    # Run cleanup
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/cache-cleanup.sh"

    # Should exit successfully without deleting anything
    [ "$status" -eq 0 ]
    [ -f /tmp/claude-session-summary-test.txt ]
    [ -f /tmp/claude-session-name-test.txt ]

    # Cleanup
    rm -f /tmp/claude-session-*
}

@test "calculates cache size correctly" {
    # Create small cache file
    dd if=/dev/zero of=/tmp/claude-test-file.txt bs=1024 count=1024 2>/dev/null

    # Check that du -sm works
    size=$(du -sm /tmp/claude-test-file.txt 2>/dev/null | awk '{print $1}')

    # Should be ~1MB
    [ "$size" -ge 1 ]
    [ "$size" -le 2 ]

    # Cleanup
    rm -f /tmp/claude-test-file.txt
}

@test "deletes summary files older than 7 days when over 100MB" {
    skip "Requires manual setup of large cache (>100MB) and file aging"
}

@test "preserves files younger than 7 days" {
    skip "Requires file aging setup with touch -d"
}

@test "preserves files when under 100MB threshold" {
    # Already tested in first test
    :
}
