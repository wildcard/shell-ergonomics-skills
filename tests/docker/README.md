# Docker Integration Tests

This directory contains Docker-based integration tests for verifying the plugin installs correctly in a fresh Claude Code environment.

## Files

- **`Dockerfile`** - Builds a container with Node.js 20, Claude Code CLI, and all dependencies
- **`test-install.sh`** - Verification script that tests plugin structure and configuration
- **`docker-compose.yml`** - Orchestration config for easy testing

## Quick Start

```bash
# Using docker-compose (recommended)
docker compose -f tests/docker/docker-compose.yml up --build

# Or build and run directly
docker build -f tests/docker/Dockerfile -t plugin-test .
docker run --rm plugin-test
```

## What Gets Tested

1. **Plugin Structure**
   - `plugin.json` exists and is valid JSON
   - Required fields present: name, version, description

2. **Hooks Configuration**
   - `hooks/hooks.json` is valid JSON
   - Contains expected hook types

3. **Script Executability**
   - All `.sh` files in `hooks/scripts/` are executable

4. **Skill Structure**
   - `SKILL.md` has YAML frontmatter
   - Required fields: name, description

5. **Dependencies**
   - jq is installed
   - starship is installed
   - Claude Code CLI is available

6. **Claude Code Integration**
   - CLI supports `--plugin-dir` flag
   - Version command works

7. **Statusline Execution** (NEW)
   - Creates mock git project and session
   - Simulates Claude Code JSON input
   - Verifies 3-line output format:
     - Line 1: emoji, model, git branch, context %
     - Line 2: summary, tools, session ID
     - Line 3: session name, plan indicator
   - Validates cache file integration
   - Confirms Starship git integration works

## Expected Output

```
ℹ Testing plugin.json...
✓ plugin.json has all required fields (name: shell-ergonomics-skills, version: 1.0.0)
ℹ Testing hooks configuration...
✓ hooks.json is valid JSON
✓ hooks.json contains 3 hook type(s)
ℹ Testing hook scripts...
✓ session-naming.sh is executable
✓ plan-tracking.sh is executable
✓ assistant-output-sampling.sh is executable
✓ cache-cleanup.sh is executable
ℹ Testing skill structure...
✓ SKILL.md has YAML frontmatter
✓ SKILL.md has required frontmatter fields (name: advanced-statusline)
ℹ Testing statusline script...
✓ statusline-wrapper.sh is executable
ℹ Testing Claude Code plugin loading...
✓ Claude Code CLI is installed
✓ Claude Code version: X.X.X
✓ Claude Code supports --plugin-dir flag
ℹ Testing dependencies...
✓ jq is installed
✓ starship is installed
ℹ Testing statusline execution...
✓ Statusline script executed successfully
✓ Statusline output has 3 lines
✓ Line 1 contains model name
✓ Line 1 contains context percentage
✓ Line 2 contains session ID
✓ Line 2 contains tool indicator
✓ Line 3 contains session name from cache
✓ Line 3 contains plan indicator

ℹ Statusline output:
💼 Claude 3.5 Sonnet | main | 3% ctx
Testing plugin installation 🔧 Read, Write, Edit | test-session-abc123
Test Session Name 📋 test-plan

=========================================
Test Summary
=========================================
Passed: 23
Failed: 0
=========================================
✓ All tests passed!
```

## CI/CD Integration

Add to `.github/workflows/test.yml`:

```yaml
docker-test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Run Docker integration test
      run: docker compose -f tests/docker/docker-compose.yml up --build --exit-code-from plugin-test
```

## Troubleshooting

**Build fails on Starship install:**
- Check internet connection
- Try building with `--no-cache` flag

**Tests fail with "not executable":**
- Ensure scripts have execute permissions before building
- Check that `.gitattributes` doesn't strip executable bits

**Container exits immediately:**
- Check logs: `docker compose -f tests/docker/docker-compose.yml logs`
- Verify test script syntax: `bash -n tests/docker/test-install.sh`
