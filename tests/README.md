# Test Suite

Comprehensive test suite for the shell-ergonomics-skills plugin using [bats-core](https://github.com/bats-core/bats-core).

## Requirements

```bash
# Install bats-core
brew install bats-core

# Or via npm
npm install -g bats

# Required for plugin functionality
brew install jq starship
```

## Running Tests

### Run all tests
```bash
cd ~/workspace/shell-ergonomics-skills
bats tests/*.bats
```

### Run specific test file
```bash
bats tests/session_naming.bats
bats tests/statusline_wrapper.bats
```

### Run with verbose output
```bash
bats --tap tests/*.bats
```

## Test Coverage

### `session_naming.bats`
Tests AI-powered session name generation:
- ✅ Message counting and threshold detection
- ✅ Cache file handling and persistence
- ✅ Claude API integration with Haiku model
- ✅ Prompt caching for performance
- ✅ Fallback behavior on errors
- ✅ JSON response parsing

### `plan_tracking.bats`
Tests plan mode detection and indicator display:
- ✅ Plan mode state detection (entering/exiting)
- ✅ Cache file creation and updates
- ✅ Plan indicator emoji output
- ✅ State persistence across sessions
- ✅ Edge cases (missing files, malformed data)

### `assistant_sampling.bats`
Tests tool usage tracking from assistant output:
- ✅ Tool name extraction from JSON
- ✅ Top-3 tool display logic
- ✅ Tool frequency counting
- ✅ Cache file updates
- ✅ Output formatting with emojis

### `cache_cleanup.bats`
Tests intelligent cache cleanup strategy:
- ✅ Size threshold detection (100MB)
- ✅ Age-based file retention (7 days)
- ✅ Cache directory size calculation
- ✅ Selective file deletion
- ✅ Error handling for missing directories

### `statusline_wrapper.bats`
Tests the main statusline display logic:
- ✅ Three-line output format
- ✅ Starship integration
- ✅ Context percentage calculation
- ✅ Session ID extraction
- ✅ Summary and plan indicator display
- ✅ Tool usage formatting
- ✅ Error handling and fallbacks

## Test Helpers

`test_helper.bash` provides common utilities:
- `setup()` - Creates temporary test directories
- `teardown()` - Cleans up test artifacts
- Mock environment variable setup
- Fixture file loading (when needed)

## Fixtures

`tests/fixtures/` directory for test data files (currently empty, populated as needed).

## Writing New Tests

### Test Structure
```bash
#!/usr/bin/env bats

load test_helper

@test "descriptive test name" {
  # Arrange
  export CLAUDE_SESSION_ID="test-session"

  # Act
  run bash "${BATS_TEST_DIRNAME}/../path/to/script.sh"

  # Assert
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected pattern" ]]
}
```

### Best Practices
1. **Isolate**: Use temporary directories for cache files
2. **Mock**: Set environment variables to control behavior
3. **Assert**: Check exit codes, output patterns, and file contents
4. **Clean**: Use `teardown()` to remove test artifacts
5. **Document**: Clear test names describing what's being tested

## Environment Variables Used in Tests

- `CLAUDE_SESSION_ID` - Current session identifier
- `CLAUDE_PLUGIN_ROOT` - Plugin installation directory
- `CLAUDE_PROJECT_ROOT` - User's project directory
- `CLAUDE_CONTEXT_PERCENT` - Context window usage (0-100)
- `ANTHROPIC_API_KEY` - API key for Claude integration

## CI/CD Considerations

### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          brew install bats-core jq starship
      - name: Run tests
        run: bats tests/*.bats
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Performance Considerations

- **Prompt caching**: First test run may be slower due to API calls
- **Mocking**: Consider mocking Claude API calls for faster CI runs
- **Parallelization**: bats supports parallel execution with `--jobs N`

## Debugging Tests

### Show output even on success
```bash
bats --print-output-on-failure tests/session_naming.bats
```

### Run single test by line number
```bash
bats tests/session_naming.bats:42
```

### Enable bash debugging
```bash
BATS_TRACE=1 bats tests/*.bats
```

## Known Limitations

- API tests require valid `ANTHROPIC_API_KEY`
- Some tests require active Claude Code session context
- Starship integration tests need Starship installed
- Cache cleanup tests simulate large directories (may be slow)

## Future Enhancements

- [ ] Mock Claude API responses for faster tests
- [ ] Add integration tests with full Claude Code lifecycle
- [ ] Performance benchmarks for statusline rendering
- [ ] Cross-platform testing (Linux, macOS)
- [ ] Code coverage reporting
