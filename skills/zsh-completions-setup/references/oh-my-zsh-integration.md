# Oh My Zsh Integration

Deep dive into how Oh My Zsh handles completions and how to integrate custom completions correctly.

## Oh My Zsh Completion System

### Internal Mechanism

Oh My Zsh calls `compinit` automatically when `oh-my-zsh.sh` is sourced:

```bash
# Inside oh-my-zsh.sh (simplified)
if [ -z "$ZSH_COMPDUMP" ]; then
  ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"
fi

autoload -U compinit
compinit -d "$ZSH_COMPDUMP"
```

**Key Insight:** Any `fpath` modifications MUST happen before this line to be seen by `compinit`.

### Plugin Loading Order

```
1. ZSH variable set ($ZSH=/path/to/oh-my-zsh)
2. plugins=(...) array defined
3. fpath modifications (must go here)
4. source $ZSH/oh-my-zsh.sh
   ├─ 4a. Load plugins
   ├─ 4b. Plugins modify fpath
   ├─ 4c. compinit runs (scans current fpath)
   └─ 4d. Theme loads
```

### Why Brew Plugin Works

The brew plugin (at `~/.oh-my-zsh/plugins/brew/brew.plugin.zsh`) adds Homebrew to fpath:

```zsh
# Inside brew.plugin.zsh
if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath+=("$HOMEBREW_PREFIX/share/zsh/site-functions")
fi
```

This works because:
1. Plugin loads BEFORE compinit
2. `fpath` is modified
3. Then compinit scans the modified fpath

**However:** This relies on the plugin loading order. Manual fpath additions BEFORE `oh-my-zsh.sh` are more reliable.

## Plugin-Based Completions

### Built-in Plugins with Completions

| Plugin | Provides Completions For | Type |
|--------|--------------------------|------|
| git | Git commands, branches, tags | Built-in functions |
| brew | Homebrew commands, casks | Adds site-functions to fpath |
| docker | Docker commands, containers | Built-in functions |
| npm | npm commands, scripts | Built-in functions |
| kubectl | Kubernetes commands | Built-in functions |
| terraform | Terraform commands | Built-in functions |
| 1password | 1Password CLI (op) | Dynamic generation |

### Enable Plugins

In `~/.zshrc`:

```zsh
plugins=(
  git
  brew
  docker
  npm
  1password
)

source $ZSH/oh-my-zsh.sh
```

### Dynamic Completion Plugins

Some plugins generate completions at shell startup:

**1password plugin example:**
```zsh
# In ~/.oh-my-zsh/plugins/1password/1password.plugin.zsh
if (( ${+commands[op]} )); then
  eval "$(op completion zsh)"
  compdef _op op
fi
```

This calls `op completion zsh` every shell start, which can slow startup.

## Custom Plugin Locations

### $ZSH_CUSTOM Directory

Default: `~/.oh-my-zsh/custom`

Structure:
```
~/.oh-my-zsh/custom/
├── plugins/
│   ├── zsh-autosuggestions/
│   ├── zsh-syntax-highlighting/
│   └── zsh-completions/
├── themes/
└── functions/
```

### zsh-completions Plugin

Provides 200+ additional completions:

**Installation:**
```bash
git clone https://github.com/zsh-users/zsh-completions \
  ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
```

**Configuration in ~/.zshrc:**
```zsh
# Add to fpath BEFORE oh-my-zsh.sh
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh
```

**What it provides:**
- ansible, cargo-make, nix, poetry, rustc
- Tools not in Homebrew completions
- Updated more frequently than system completions

## Manual vs Plugin Completions

### When to Use Plugins

Use plugins when:
- Tool is frequently updated (plugins track releases)
- Community maintains the plugin (brew, docker)
- Dynamic completion needed (kubectl contexts)

### When to Generate Manually

Generate manually when:
- Tool has built-in generation (rustup, starship)
- Completion is static (doesn't change often)
- Want control over when it's updated

### Hybrid Approach

Combine both:

```zsh
# Plugins for dynamic tools
plugins=(git brew docker kubectl)

# Manual fpath for static tools
fpath+=${ZSH_CUSTOM}/plugins/zsh-completions/src
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

source $ZSH/oh-my-zsh.sh
```

## Common Integration Patterns

### Pattern 1: Homebrew-First

```zsh
# ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"

plugins=(git brew)

# Homebrew completions take priority
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

source $ZSH/oh-my-zsh.sh
```

**Use case:** Homebrew-installed tools are primary.

### Pattern 2: Plugin-Heavy

```zsh
# ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  brew
  docker
  npm
  kubectl
  terraform
  zsh-autosuggestions
  zsh-syntax-highlighting
)

fpath+=${ZSH_CUSTOM}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh
```

**Use case:** Prefer maintained plugins over manual generation.

### Pattern 3: Custom Directory

```zsh
# ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"

plugins=(git brew)

# Custom completions have highest priority
fpath=(~/.zsh/completions $fpath)
fpath+=${ZSH_CUSTOM}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh
```

**Use case:** Mix of custom-generated and plugin completions.

### Pattern 4: Selective Generation

```zsh
# ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"

plugins=(git brew docker)

# Only add Homebrew path for generated completions
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

source $ZSH/oh-my-zsh.sh

# Generate completions that change frequently
if (( ${+commands[kubectl]} )) && [ ! -f ~/.zsh/completions/_kubectl ]; then
  mkdir -p ~/.zsh/completions
  kubectl completion zsh > ~/.zsh/completions/_kubectl
fi
```

**Use case:** Balance between plugins and generation.

## Oh My Zsh Cache Directory

### Location

`~/.oh-my-zsh/cache/completions/`

Some plugins store generated completions here:

```bash
ls ~/.oh-my-zsh/cache/completions/
# _op  (from 1password plugin)
```

### When It's Used

Plugins use the cache directory for:
- Dynamically generated completions
- Temporary completion files
- Performance optimization

**1password plugin example:**
```zsh
if [ ! -f "$ZSH_CACHE_DIR/completions/_op" ]; then
  op completion zsh >| "$ZSH_CACHE_DIR/completions/_op"
fi
```

### Clearing the Cache

```bash
rm -rf ~/.oh-my-zsh/cache/completions/*
exec zsh
```

## Avoiding Conflicts

### Plugin vs Manual Completion

**Problem:** Both plugin and manual completion exist:

```bash
# Plugin provides completion
plugins=(docker)

# Also manually generated
docker completion zsh > $(brew --prefix)/share/zsh/site-functions/_docker
```

**Solution:** Choose one approach:

**Option 1: Use plugin only**
```zsh
plugins=(docker)
# Don't generate manually
```

**Option 2: Use manual only**
```zsh
plugins=(git brew)  # docker not included
# Generate manually
docker completion zsh > $(brew --prefix)/share/zsh/site-functions/_docker
```

### System vs Homebrew Completion

**Problem:** Both system and Homebrew provide the same completion:

```bash
ls /usr/share/zsh/5.9/functions/_git
ls $(brew --prefix)/share/zsh/site-functions/_git
```

**Solution:** Control with fpath order:

```zsh
# Homebrew takes priority (prepend)
fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)

# System takes priority (append)
fpath+=("$(brew --prefix)/share/zsh/site-functions")
```

## Debugging Oh My Zsh Completions

### Check Plugin fpath Additions

```bash
# After sourcing oh-my-zsh.sh
echo $fpath | tr " " "\n" | grep oh-my-zsh
# ~/.oh-my-zsh/plugins/brew
# ~/.oh-my-zsh/plugins/git
# ~/.oh-my-zsh/functions
# ~/.oh-my-zsh/completions
```

### Test Without Oh My Zsh

Temporarily disable to isolate issues:

```zsh
# In ~/.zshrc, comment out
# source $ZSH/oh-my-zsh.sh

# Manually call compinit
autoload -U compinit && compinit

# Test completions
brew <TAB>
```

### Check Plugin Loading

```zsh
# Enable Oh My Zsh debug mode
ZSH_DEBUG=1 zsh

# Shows plugin loading sequence
# plugin: git
# plugin: brew
# ...
# compinit
```

## Best Practices

### Do's

✅ Add fpath modifications BEFORE `source $ZSH/oh-my-zsh.sh`

✅ Use brew plugin when available

✅ Leverage zsh-completions for community completions

✅ Generate static completions once, use plugins for dynamic ones

✅ Keep custom completions in `~/.zsh/completions/`

### Don'ts

❌ Don't call `compinit` manually with Oh My Zsh

❌ Don't modify fpath after sourcing oh-my-zsh.sh

❌ Don't duplicate completions (plugin + manual)

❌ Don't rely on plugin load order for critical fpath entries

❌ Don't ignore completion cache issues

## Example: Complete ~/.zshrc Setup

```zsh
#!/bin/zsh
# Minimal completion setup with Oh My Zsh

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins to load
plugins=(
  git
  brew
  docker
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# === COMPLETIONS (BEFORE oh-my-zsh.sh) ===

# zsh-completions plugin
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# Homebrew completions
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

# Custom completions (highest priority)
fpath=(~/.zsh/completions $fpath)

# === LOAD OH MY ZSH ===
source $ZSH/oh-my-zsh.sh

# === POST-LOAD INITIALIZATION ===

# Tool-specific initialization (includes completions)
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"

# User configuration
export PATH="$HOME/.local/bin:$PATH"
```

This setup provides:
- Plugin completions for common tools
- Homebrew completions for installed formulas
- zsh-completions for additional tools
- Custom directory for manual additions
- Clean separation between plugins and manual setup
