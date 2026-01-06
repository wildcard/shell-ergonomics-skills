# Shell Ergonomics Skills

[![Docker Integration Tests](https://github.com/wildcard/shell-ergonomics-skills/actions/workflows/test.yml/badge.svg)](https://github.com/wildcard/shell-ergonomics-skills/actions/workflows/test.yml)

A Claude Code plugin focused on shell ergonomics: AI-powered statusline enhancements, session tracking, intelligent summaries, and developer experience improvements.

## Features

✅ **AI-Powered Statusline** - 3-line status display with Starship integration
✅ **Session Names** - Auto-generated meaningful session names using Claude Haiku
✅ **AI Summaries** - Intelligent session summaries based on your actual work
✅ **Plan Tracking** - Correlate Claude Code plans with sessions
✅ **Tool Usage Display** - Show top 3 tools used in current session
✅ **Smart Caching** - Message-count-based invalidation (idle sessions keep state)
✅ **Intelligent Cleanup** - Threshold-based cache management (only when > 100MB)

## Installation

### From Plugin Marketplace (Recommended)

#### Step 1: Add the Marketplace

```bash
/plugin marketplace add wildcard/shell-ergonomics-skills
```

#### Step 2: Install the Plugin

```bash
/plugin install shell-ergonomics-skills@wildcard
```

#### Step 3: Configure Statusline

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/cache/shell-ergonomics-skills/skills/advanced-statusline/scripts/statusline-wrapper.sh"
  }
}
```

Then restart Claude Code.

### Development Installation

```bash
# Clone the repository
git clone git@github.com:wildcard/shell-ergonomics-skills.git

# Run Claude Code with the plugin loaded
claude --plugin-dir ./shell-ergonomics-skills
```

For development, configure statusline in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /path/to/your/clone/shell-ergonomics-skills/skills/advanced-statusline/scripts/statusline-wrapper.sh"
  }
}
```

Replace `/path/to/your/clone` with your actual clone path, then restart Claude Code.

## Requirements

- [Starship](https://starship.rs/) - `brew install starship`
- [jq](https://stedolan.github.io/jq/) - `brew install jq`
- Claude Code CLI

## Statusline Output

The statusline displays 3 lines:

```
🦀 Claude 3.5 Sonnet | main via 🦀 v1.74.0 | 45% ctx
Creating plugin project with tests 🔧 Read, Write, Edit | 1370c291
Shell ergonomics skills 📋 curious-noodling-catmull
```

**Line 1:** Workspace emoji, model, git branch (via Starship), context percentage
**Line 2:** AI-generated summary, tool usage, session ID
**Line 3:** Session name, plan indicator

## How It Works

### Hooks

The plugin registers hooks that run automatically:

- **UserPromptSubmit**: Generate session names, track plans
- **PostToolUse**: Record tool usage for display
- **SessionStart**: Initialize plan tracking

### Caching Strategy

- **Message-count-based**: Only regenerate when NEW user messages arrive
- **Idle preservation**: Sessions idle for days keep their cached state
- **Cleanup threshold**: Only delete old files when cache > 100MB
- **Age-based retention**: Keep files < 7 days old

### AI Integration

Uses Claude Haiku with structured output for:
- Session summaries (60 char max)
- Session names (40 char max, 3-5 words)
- Prompt caching for fast subsequent calls

## Testing

See [tests/README.md](tests/README.md) for the test suite using bats-core.

```bash
# From the plugin directory
bats tests/*.bats
```

## Troubleshooting

**Statusline shows errors:**
- Install Starship: `brew install starship`
- Install jq: `brew install jq`

**Hooks don't run:**
- Restart Claude Code (hooks load at session start)
- Check script permissions: `ls -la hooks/scripts/`

**AI summaries timeout:**
- First run takes longer (no cache)
- Subsequent runs use prompt caching (faster)
- Fallback to user messages if timeout occurs

## License

MIT
