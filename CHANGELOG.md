# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-01-02

### Fixed
- **Critical: Race condition causing "Unnamed Session" in statusline**
  - Session naming hook now writes readable fallback name IMMEDIATELY before AI call
  - Eliminates 5-second window where statusline showed "Unnamed Session"
  - Fallback uses word-boundary truncation with proper capitalization
  - AI call attempts to upgrade fallback name asynchronously (5-second timeout)
  - If AI succeeds: overwrites fallback with better AI-generated name
  - If AI fails/times out: keeps readable fallback name
  - User impact: Session name appears instantly instead of showing "Unnamed Session"

- Integer comparison bugs in session-naming.sh and statusline-wrapper.sh
  - Fixed grep -c output causing failures in message count comparisons
  - Added tr -d '\n\r' to sanitize grep output
  - Added safety defaults ${var:-0} to prevent empty variable errors
  - Prevents script exit when using set -euo pipefail

### Added
- New test: "cache exists immediately even when AI times out" (test #38)
  - Verifies cache file created BEFORE AI call completes
  - Ensures fallback name is readable (not truncated mid-word)
  - Confirms proper sentence case capitalization
  - Total test coverage: 21 session naming tests, 47 tests across entire project

### Changed
- **Complete SKILL.md documentation refresh**
  - Updated session-naming.sh code example (lines 78-220) with race condition fix
  - Added immediate fallback write documentation
  - Updated component descriptions to mention race condition prevention
  - Expanded cache files table to include msgcount and AI temp files
  - Documented regeneration logic with immediate fallback + AI upgrade strategy
  - Updated timeout from 2 seconds to 5 seconds in examples
  - Added proper error handling examples with || true

- Cache cleanup improvements
  - Added cleanup for claude-session-name-ai-*.json temp files
  - Maintains 1-hour cleanup policy for AI temp files

### Technical Details
- Immediate fallback algorithm uses word-by-word parsing with 37-char limit
- AI upgrade process runs in background with 5-second timeout
- Structured JSON output: {"name": "Session Name Here"}
- Fallback preserved if AI name is empty or < 5 characters
- Message count tracking enables smart regeneration on new prompts

## [1.0.2] - 2026-01-02

### Fixed
- Comprehensive bug fixes and test improvements for session naming
  - Fixed integer comparison bugs in session-naming.sh (lines 37-40, 52-53)
  - Fixed process cleanup exit codes (lines 84-85)
  - Fixed jq command substitution error handling (line 90)
  - Improved fallback naming with word-boundary truncation

### Added
- Comprehensive session naming test suite (20 tests total)
  - 10 mock-based tests (no API key required)
  - 3 real Haiku API tests (require ANTHROPIC_API_KEY)
  - 2 fallback quality tests
  - Tests for cache hit/invalidation, timestamps, message counts
  - Tests for special character handling

- Message count-based regeneration
  - Session names regenerate when new messages arrive
  - Tracks message count in .msgcount files
  - Prevents stale names in long-running sessions

### Changed
- Session naming now uses word-boundary truncation for fallbacks
  - Before: "write a tests to test for the session na" (mid-word)
  - After: "Write a tests to test for the session..." (readable)
  - Capitalizes first word for proper sentence case
  - Adds ellipsis only when text is truncated

## [1.0.1] - 2026-01-02

### Fixed
- Fixed integer comparison error in statusline script (line 125)
  - Strip newlines and whitespace from message count variables
  - Add safety defaults to prevent "integer expression expected" errors
  - Ensures clean comparison even when cache files have trailing newlines

## [1.0.0] - 2025-12-31

### Added
- Initial release of shell-ergonomics-skills plugin
- Advanced statusline with AI-powered session summaries
- Session naming hook that generates meaningful names from first substantial prompt
- Plan tracking hook that associates sessions with recently modified plan files
- Assistant output sampling hook that tracks tool usage patterns
- Cache cleanup hook that manages /tmp files to prevent disk bloat
- Comprehensive test suite with bats-core (24+ tests)
- Support for workspace-specific emojis (Rust, Node, Python, etc.)
- Context usage percentage display in statusline
- Cached summaries to reduce API calls
- Fallback mechanisms when AI services are unavailable

### Features
- **Smart Caching**: Caches session names and summaries to minimize API usage
- **Workspace Detection**: Automatically detects project type and displays appropriate emoji
- **Plan Association**: Links sessions to recently modified plan files
- **Tool Analytics**: Tracks and summarizes most-used tools per session
- **Automatic Cleanup**: Removes stale cache files older than 7 days when cache exceeds 100MB

### Technical
- All scripts use `${CLAUDE_PLUGIN_ROOT}` for portability
- Hook configuration via `hooks.json` for automatic discovery
- Skill-based architecture for easy extension
- POSIX-compliant shell scripts for maximum compatibility
