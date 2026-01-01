#!/usr/bin/env zsh
# Verify zsh completions are properly configured and loaded
#
# Checks:
#   - fpath configuration
#   - Completion cache status
#   - Specific completion functions
#   - Common issues
#
# Usage:
#   zsh verify-completions.sh

# Enable colors if terminal supports it
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

ISSUES=0

# Helper functions
ok() { echo "${GREEN}✓${NC} $1"; }
warn() { echo "${YELLOW}⚠${NC} $1"; ((ISSUES++)); }
error() { echo "${RED}✗${NC} $1"; ((ISSUES++)); }
info() { echo "${BLUE}ℹ${NC} $1"; }

echo "=== Zsh Completions Verification ==="
echo ""

# Check 1: Homebrew path in fpath
echo "Checking fpath configuration..."
if command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  BREW_SITE_FUNCTIONS="${BREW_PREFIX}/share/zsh/site-functions"

  if echo "$fpath" | grep -q "$BREW_SITE_FUNCTIONS"; then
    ok "Homebrew completions path in fpath: $BREW_SITE_FUNCTIONS"
  else
    error "Homebrew completions path NOT in fpath"
    info "Add to ~/.zshrc BEFORE 'source \$ZSH/oh-my-zsh.sh':"
    info "  fpath=(\"\$(brew --prefix)/share/zsh/site-functions\" \$fpath)"
  fi
else
  warn "Homebrew not installed (skipping Homebrew checks)"
fi

# Check 2: Custom completions path
if [[ -d "$HOME/.zsh/completions" ]]; then
  if echo "$fpath" | grep -q "$HOME/.zsh/completions"; then
    ok "Custom completions path in fpath: ~/.zsh/completions"
  else
    warn "~/.zsh/completions exists but not in fpath"
    info "Add to ~/.zshrc: fpath=(~/.zsh/completions \$fpath)"
  fi
fi

# Check 3: Completion cache
echo ""
echo "Checking completion cache..."
if [[ -f "$HOME/.zcompdump" ]]; then
  CACHE_AGE=$(($(date +%s) - $(stat -f %m "$HOME/.zcompdump" 2>/dev/null || stat -c %Y "$HOME/.zcompdump")))
  CACHE_AGE_DAYS=$((CACHE_AGE / 86400))

  ok "Completion cache exists: ~/.zcompdump"
  info "Cache age: $CACHE_AGE_DAYS days"

  if [[ $CACHE_AGE_DAYS -gt 30 ]]; then
    warn "Cache is older than 30 days (consider rebuilding)"
    info "Run: rm -f ~/.zcompdump* && exec zsh"
  fi

  # Check for .zwc compiled cache
  if [[ -f "$HOME/.zcompdump.zwc" ]]; then
    ok "Compiled cache exists (faster startup)"
  else
    info "No compiled cache (still works, but slower startup)"
  fi
else
  error "Completion cache missing"
  info "Run: compinit"
fi

# Check 4: Common completion functions
echo ""
echo "Checking common completions..."

COMPLETIONS=(
  "_brew:brew:Homebrew"
  "_git:git:Git"
  "_rustup:rustup:Rust toolchain"
  "_cargo:cargo:Cargo"
  "_npm:npm:npm"
  "_docker:docker:Docker"
)

for entry in "${COMPLETIONS[@]}"; do
  IFS=: read -r func tool name <<< "$entry"

  if ! command -v "$tool" &>/dev/null; then
    continue  # Skip if tool not installed
  fi

  # Use whence to check if completion function exists
  if whence -w "$func" &>/dev/null; then
    LOCATION=$(whence -v "$func" | sed 's/.* from //')
    ok "$name completion loaded"
    if [[ ! "$LOCATION" =~ "not found" ]]; then
      info "  Source: $LOCATION"
    fi
  else
    error "$name completion NOT loaded (tool installed: $tool)"

    # Try to diagnose
    if [[ -n "${BREW_PREFIX:-}" ]] && [[ -f "${BREW_SITE_FUNCTIONS}/${func}" ]]; then
      info "  File exists: ${BREW_SITE_FUNCTIONS}/${func}"
      info "  Rebuild cache: rm -f ~/.zcompdump* && exec zsh"
    elif [[ -f "$HOME/.zsh/completions/${func}" ]]; then
      info "  File exists: ~/.zsh/completions/${func}"
      info "  Ensure fpath includes: ~/.zsh/completions"
    fi
  fi
done

# Check 5: fpath order
echo ""
echo "Checking fpath order..."
echo "$fpath" | tr ' ' '\n' | nl -w2 -s'. '

info "Completions are searched in order (first match wins)"
info "Ensure important paths come first"

# Check 6: Oh My Zsh integration
echo ""
echo "Checking Oh My Zsh integration..."
if [[ -n "${ZSH:-}" ]]; then
  ok "Oh My Zsh detected: $ZSH"

  # Check if compinit was called manually
  if grep -q "^autoload.*compinit" "$HOME/.zshrc" 2>/dev/null; then
    warn "Manual compinit call found in ~/.zshrc"
    info "Oh My Zsh calls compinit automatically - manual call may cause issues"
    info "Remove: autoload -U compinit && compinit"
  else
    ok "No manual compinit call (Oh My Zsh handles it)"
  fi

  # Check brew plugin
  if [[ -n "${plugins:-}" ]] && echo "${plugins[@]}" | grep -q "brew"; then
    ok "Oh My Zsh brew plugin enabled"
  else
    info "Oh My Zsh brew plugin not enabled (fpath modification still works)"
  fi
else
  info "Oh My Zsh not detected (vanilla zsh)"
fi

# Summary
echo ""
echo "=== Summary ==="
if [[ $ISSUES -eq 0 ]]; then
  ok "All checks passed!"
  echo ""
  echo "Test completions:"
  echo "  brew <TAB>"
  echo "  git <TAB>"
  echo "  cargo <TAB>"
else
  error "Found $ISSUES issue(s)"
  echo ""
  echo "Common fixes:"
  echo "  1. Rebuild cache: rm -f ~/.zcompdump* && exec zsh"
  echo "  2. Check ~/.zshrc: fpath before oh-my-zsh.sh"
  echo "  3. Generate missing completions: see examples/generate-completions.sh"
fi

exit $ISSUES
