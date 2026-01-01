#!/usr/bin/env bash
# Generate zsh completions for all supported CLI tools
#
# Usage:
#   ./generate-completions.sh [--homebrew|--user]
#
# Options:
#   --homebrew    Save to Homebrew directory (default, requires ownership)
#   --user        Save to ~/.zsh/completions (always works)

set -euo pipefail

# Determine target directory
TARGET_DIR=""
if [[ "${1:-}" == "--user" ]]; then
  TARGET_DIR="$HOME/.zsh/completions"
  mkdir -p "$TARGET_DIR"
  echo "Generating completions to: $TARGET_DIR"
elif command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  TARGET_DIR="${BREW_PREFIX}/share/zsh/site-functions"
  echo "Generating completions to: $TARGET_DIR (Homebrew)"
else
  echo "Error: Homebrew not found. Use --user flag to save to ~/.zsh/completions"
  exit 1
fi

# Counter for generated completions
COUNT=0

# Function to generate completion
generate() {
  local tool="$1"
  local cmd="$2"
  local output_file="${TARGET_DIR}/_${tool}"

  if ! command -v "$tool" &>/dev/null; then
    echo "⏭️  Skipping $tool (not installed)"
    return
  fi

  echo "Generating completion for $tool..."
  if eval "$cmd" > "$output_file" 2>/dev/null; then
    local size=$(du -h "$output_file" | cut -f1)
    echo "✅ $tool ($size)"
    COUNT=$((COUNT + 1))
  else
    echo "❌ $tool (generation failed)"
    rm -f "$output_file"
  fi
}

echo ""
echo "=== Rust Ecosystem ==="
generate rustup "rustup completions zsh rustup"
generate cargo "rustup completions zsh cargo"

echo ""
echo "=== Python Tools ==="
generate uv "uv generate-shell-completion zsh"
generate pipx "pipx completions"
generate pdm "pdm completion zsh"

echo ""
echo "=== Shell Tools ==="
generate starship "starship completions zsh"
generate atuin "atuin gen-completions --shell zsh"

echo ""
echo "=== File Tools ==="
generate rclone "rclone completion zsh -"
generate fclones "fclones complete zsh"

echo ""
echo "=== Git Tools ==="
generate gh "gh completion -s zsh"

echo ""
echo "=== Package Managers ==="
# Note: npm system completion is often better
# generate npm "npm completion"
generate pnpm "pnpm completion zsh"
generate bun "bun completions"

echo ""
echo "=== Security Tools ==="
generate op "op completion zsh"

echo ""
echo "=== Build Tools ==="
generate mise "mise completion zsh"
generate just "just --completions zsh"

echo ""
echo "=== Summary ==="
echo "Generated $COUNT completions in $TARGET_DIR"

if [[ "$TARGET_DIR" == *"homebrew"* ]]; then
  echo ""
  echo "Homebrew completions will be auto-discovered if:"
  echo "  fpath includes: \$(brew --prefix)/share/zsh/site-functions"
else
  echo ""
  echo "Add to your ~/.zshrc BEFORE 'source \$ZSH/oh-my-zsh.sh':"
  echo "  fpath=(~/.zsh/completions \$fpath)"
fi

echo ""
echo "Rebuild completion cache:"
echo "  rm -f ~/.zcompdump* && exec zsh"
