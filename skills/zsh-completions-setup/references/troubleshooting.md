# Troubleshooting Zsh Completions

Detailed solutions for common completion problems based on real troubleshooting scenarios.

## Problem: Nothing Works After Configuration Changes

### Symptom
- Added Homebrew path to fpath
- Configurations look correct
- `brew <TAB>` shows nothing
- Other completions also broken

### Diagnosis
```bash
# Check if completions exist
ls $(brew --prefix)/share/zsh/site-functions/_brew  # Should exist

# Check if they're loaded
whence -v _brew  # Shows "not found"
```

### Root Cause
The completion cache (`.zcompdump*` files) is stale and doesn't include the new fpath entries.

### Solution
```bash
# Delete ALL cache files (including .zwc compiled versions)
rm -f ~/.zcompdump*

# Restart shell to rebuild cache
exec zsh

# Verify completions are now found
whence -v _brew
# Expected: _brew is an autoload shell function from /opt/homebrew/share/zsh/site-functions/_brew
```

### Prevention
Always rebuild the cache after fpath changes:
```bash
rm -f ~/.zcompdump* && exec zsh
```

---

## Problem: Homebrew Path Not in fpath

### Symptom
```bash
echo $fpath | tr " " "\n" | grep homebrew
# No output - Homebrew path missing
```

### Diagnosis
```bash
# Check .zshrc configuration
grep "brew --prefix" ~/.zshrc

# Check order relative to oh-my-zsh.sh
grep -n "brew\|oh-my-zsh.sh" ~/.zshrc
```

### Root Cause #1: Wrong Order
```zsh
# WRONG - fpath added AFTER compinit runs
source $ZSH/oh-my-zsh.sh  # Line 79: calls compinit
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)  # Line 85: too late
fi
```

### Solution #1
Move the fpath addition BEFORE `source $ZSH/oh-my-zsh.sh`:

```zsh
# Correct order
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

source $ZSH/oh-my-zsh.sh
```

### Root Cause #2: Manual compinit Call
```zsh
# WRONG - Manual compinit before fpath changes
autoload -U compinit && compinit  # Line 77
fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)  # Line 78
source $ZSH/oh-my-zsh.sh  # Line 79
```

### Solution #2
Remove manual `compinit` call - Oh My Zsh handles it:

```zsh
# Remove this line entirely
# autoload -U compinit && compinit  ← DELETE

fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
source $ZSH/oh-my-zsh.sh
```

---

## Problem: Completions in Wrong Location

### Symptom
Generated completion file but it's not found:

```bash
# Generated completion
npm completion > /opt/homebrew/share/zsh/site-functions/_npm

# But not found
whence -v _npm
# _npm is an autoload shell function from /usr/share/zsh/5.9/functions/_npm
```

### Diagnosis
System completion is found first because `/usr/share/zsh` appears earlier in fpath:

```bash
echo $fpath | tr " " "\n"
# /usr/share/zsh/5.9/functions  ← System path (first)
# /opt/homebrew/share/zsh/site-functions  ← Homebrew path (second)
```

### Root Cause
fpath is searched in order. System paths often come first.

### Solution Option 1: Prepend to fpath
```zsh
# Use array prepending to put Homebrew first
fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
# NOT: fpath+=("...") which appends
```

### Solution Option 2: Remove System Completion
```bash
# If system completion is outdated/broken
sudo rm /usr/share/zsh/5.9/functions/_npm

# Rebuild cache
rm -f ~/.zcompdump* && exec zsh
```

### Solution Option 3: Use Different Location
```bash
# Save to user directory instead
mkdir -p ~/.zsh/completions
npm completion > ~/.zsh/completions/_npm

# Add to fpath (prepend for priority)
fpath=(~/.zsh/completions $fpath)
```

---

## Problem: Permission Denied Generating Completions

### Symptom
```bash
rustup completions zsh > /opt/homebrew/share/zsh/site-functions/_rustup
# Permission denied
```

### Diagnosis
```bash
ls -ld /opt/homebrew/share/zsh/site-functions/
# drwxr-xr-x root admin
# Owned by root, not current user
```

### Root Cause
Homebrew directory ownership varies by installation method.

### Solution Option 1: Fix Ownership
```bash
# If Homebrew is in /opt/homebrew (Apple Silicon)
sudo chown -R $(whoami) /opt/homebrew/share/zsh/site-functions/

# Then generate completions
rustup completions zsh > /opt/homebrew/share/zsh/site-functions/_rustup
```

### Solution Option 2: Use User Directory
```bash
# Create user-owned directory
mkdir -p ~/.zsh/completions

# Generate to user directory
rustup completions zsh > ~/.zsh/completions/_rustup

# Add to fpath in ~/.zshrc
fpath=(~/.zsh/completions $fpath)
source $ZSH/oh-my-zsh.sh
```

---

## Problem: Completions Work but Show Wrong Content

### Symptom
- `brew <TAB>` works but shows outdated subcommands
- Recently added brew commands don't appear

### Diagnosis
```bash
# Check completion file date
ls -l $(brew --prefix)/share/zsh/site-functions/_brew
# -rw-r--r-- 1 user admin 149119 Dec 25  2023 _brew

# Check brew version
brew --version
# Homebrew 4.2.0 (2025-01-15)
# Completion file is 1+ years old
```

### Root Cause #1: Outdated Completion File
Homebrew updates don't automatically update completion files.

### Solution #1
```bash
# Reinstall formula that provides completion
brew reinstall brew

# Or regenerate if tool supports it
brew generate-man-completions

# Rebuild cache
rm -f ~/.zcompdump* && exec zsh
```

### Root Cause #2: Stale Compiled Cache
The `.zwc` compiled cache is outdated.

### Solution #2
```bash
# Remove compiled cache
rm -f ~/.zcompdump*.zwc

# Restart shell
exec zsh
```

---

## Problem: Some Completions Work, Others Don't

### Symptom
```bash
whence -v _brew    # Found
whence -v _rustup  # Not found
whence -v _cargo   # Not found
```

### Diagnosis
```bash
# Check if files exist
ls -l $(brew --prefix)/share/zsh/site-functions/_rustup
ls -l $(brew --prefix)/share/zsh/site-functions/_cargo

# Check current fpath
echo $fpath | tr " " "\n" | grep homebrew
```

### Root Cause #1: Files Don't Exist
Generated completions were never created or saved to wrong location.

### Solution #1
```bash
# Generate missing completions
rustup completions zsh rustup > $(brew --prefix)/share/zsh/site-functions/_rustup
rustup completions zsh cargo > $(brew --prefix)/share/zsh/site-functions/_cargo

# Rebuild cache
rm -f ~/.zcompdump* && exec zsh
```

### Root Cause #2: Extended Attributes Block Loading
macOS quarantine attributes prevent loading.

### Diagnosis #2
```bash
ls -l@ $(brew --prefix)/share/zsh/site-functions/_rustup
# -rw-r--r--@ 1 user admin 56552 Dec 31 22:01 _rustup
#   com.apple.provenance   11
```

### Solution #2
```bash
# Remove quarantine attributes
xattr -d com.apple.provenance $(brew --prefix)/share/zsh/site-functions/_rustup
xattr -d com.apple.provenance $(brew --prefix)/share/zsh/site-functions/_cargo

# Or remove all extended attributes
xattr -c $(brew --prefix)/share/zsh/site-functions/_rustup
xattr -c $(brew --prefix)/share/zsh/site-functions/_cargo

# Rebuild cache
rm -f ~/.zcompdump* && exec zsh
```

---

## Problem: Slow Shell Startup After Adding Completions

### Symptom
Shell takes 2-3 seconds to start after adding many completions.

### Diagnosis
```bash
# Time shell startup
time zsh -i -c exit

# Count completions
ls $(brew --prefix)/share/zsh/site-functions/_* | wc -l
# 50+
```

### Root Cause
compinit scans all completion files on every shell start.

### Solution: Enable Completion Caching
```zsh
# In ~/.zshrc BEFORE source $ZSH/oh-my-zsh.sh

# Skip security checks for faster startup
autoload -Uz compinit
if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null) ]; then
  compinit
else
  compinit -C
fi

source $ZSH/oh-my-zsh.sh
```

This only rebuilds the cache once per day instead of every shell start.

---

## Problem: rclone Completion Shows Minimal Content

### Symptom
```bash
cat $(brew --prefix)/share/zsh/site-functions/_rclone
# 62 bytes - very small file
# Basic compdef only
```

### Diagnosis
```bash
# Check generation command used
history | grep rclone
# rclone completion zsh > _rclone  ← Missing the dash
```

### Root Cause
`rclone completion zsh` requires a trailing `-` to output to stdout.

### Solution
```bash
# Remove incorrect version
rm $(brew --prefix)/share/zsh/site-functions/_rclone

# Regenerate with correct command
rclone completion zsh - > $(brew --prefix)/share/zsh/site-functions/_rclone

# Verify size
ls -lh $(brew --prefix)/share/zsh/site-functions/_rclone
# Should be several KB, not 62 bytes

# Rebuild cache
rm -f ~/.zcompdump* && exec zsh
```

---

## Problem: Completions Work in New Shell but Not Current Shell

### Symptom
```bash
# In current shell
whence -v _rustup
# _rustup not found

# In new shell
zsh
whence -v _rustup
# _rustup is an autoload shell function
```

### Root Cause
Current shell's completion cache was loaded before files were added.

### Solution
```bash
# Reload completion system in current shell
autoload -U compinit && compinit

# Or just restart shell
exec zsh
```

**Note:** Changes to fpath in a running shell won't take effect until compinit is called again.

---

## Diagnostic Commands Summary

```bash
# Check if Homebrew path is in fpath
echo $fpath | tr " " "\n" | grep homebrew

# List all available completion files
ls $(brew --prefix)/share/zsh/site-functions/_*

# Check if specific completion is loaded
whence -v _brew
whence -v _rustup

# View completion function source
whence -f _brew | head -20

# Check completion cache
ls -lh ~/.zcompdump*

# Find where a completion comes from
whence -v _npm
# _npm is an autoload shell function from /usr/share/zsh/5.9/functions/_npm

# Test completion manually
compdef -d brew   # Undefine brew completion
compdef _brew brew  # Re-register it
```

## Prevention Checklist

Before reporting "completions don't work":

- [ ] Homebrew path added to fpath BEFORE `source $ZSH/oh-my-zsh.sh`
- [ ] No manual `compinit` call when using Oh My Zsh
- [ ] Completion cache rebuilt: `rm -f ~/.zcompdump* && exec zsh`
- [ ] Completion files exist in expected location
- [ ] No extended attributes blocking file loading
- [ ] fpath order puts desired paths first
- [ ] Shell restarted after configuration changes
