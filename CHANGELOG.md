# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
