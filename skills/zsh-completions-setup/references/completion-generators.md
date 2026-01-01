# Completion Generators Reference

Comprehensive list of CLI tools that can generate their own zsh completions, organized by category and tested command patterns.

## Discovery Patterns

Test these command patterns to check if a tool supports completion generation:

```bash
# Pattern 1: completion subcommand (most common)
<tool> completion zsh
<tool> completion --help

# Pattern 2: completions (plural)
<tool> completions zsh
<tool> completions --help

# Pattern 3: complete
<tool> complete zsh

# Pattern 4: generate-* variants
<tool> generate-completion zsh
<tool> generate-shell-completion zsh
<tool> gen-completions --shell zsh

# Pattern 5: --completion flag
<tool> --completion zsh
<tool> --generate-completion zsh

# Pattern 6: help search
<tool> --help | grep -i completion
<tool> help | grep -i completion
```

## Verified Working Commands

### Rust Ecosystem

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| rustup | `rustup completions zsh rustup` | stdout | Rust toolchain manager |
| cargo | `rustup completions zsh cargo` | stdout | Via rustup, not cargo directly |
| rustc | `rustup completions zsh rustc` | stdout | Rust compiler |
| rustfmt | `rustup completions zsh rustfmt` | stdout | Rust formatter |
| clippy | `rustup completions zsh clippy` | stdout | Rust linter |

**Usage:**
```bash
rustup completions zsh rustup > $(brew --prefix)/share/zsh/site-functions/_rustup
rustup completions zsh cargo > $(brew --prefix)/share/zsh/site-functions/_cargo
```

### Python Package Managers

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| uv | `uv generate-shell-completion zsh` | stdout | Modern Python package installer |
| pipx | `pipx completions` | stdout | Python application installer |
| poetry | Built-in plugin | N/A | Requires poetry shell plugin |
| pdm | `pdm completion zsh` | stdout | Python dependency manager |

**Usage:**
```bash
uv generate-shell-completion zsh > $(brew --prefix)/share/zsh/site-functions/_uv
pipx completions > $(brew --prefix)/share/zsh/site-functions/_pipx
pdm completion zsh > $(brew --prefix)/share/zsh/site-functions/_pdm
```

### Cloud & DevOps (Not Available)

Most major cloud tools do NOT provide built-in zsh completion generation:

- ❌ docker - No completion generation (use system completion or oh-my-zsh plugin)
- ❌ kubectl - No completion generation (use system completion)
- ❌ helm - No completion generation
- ❌ terraform - No completion generation
- ❌ aws - AWS CLI v2 doesn't generate completions
- ❌ gcloud - No completion generation
- ❌ az (Azure CLI) - No completion generation

**Note:** These tools may have completions available through package managers or oh-my-zsh plugins, but lack built-in generation.

### Shell & Terminal Tools

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| starship | `starship completions zsh` | stdout | Shell prompt |
| atuin | `atuin gen-completions --shell zsh` | stdout | Shell history manager |
| zoxide | `zoxide init zsh` | stdout | Includes completions in init |
| fzf | `fzf --zsh` | stdout | Fuzzy finder (v0.48+) |

**Usage:**
```bash
starship completions zsh > $(brew --prefix)/share/zsh/site-functions/_starship
atuin gen-completions --shell zsh > $(brew --prefix)/share/zsh/site-functions/_atuin
# zoxide: Use eval "$(zoxide init zsh)" in .zshrc instead
```

### File & Storage Tools

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| rclone | `rclone completion zsh -` | stdout | Note the trailing `-` |
| fclones | `fclones complete zsh` | stdout | Duplicate file finder |

**Usage:**
```bash
rclone completion zsh - > $(brew --prefix)/share/zsh/site-functions/_rclone
fclones complete zsh > $(brew --prefix)/share/zsh/site-functions/_fclones
```

### Git & VCS Tools

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| gh | `gh completion -s zsh` | stdout | GitHub CLI |
| git-lfs | No generation | N/A | Use Homebrew completion |

**Usage:**
```bash
gh completion -s zsh > $(brew --prefix)/share/zsh/site-functions/_gh
```

### Package Managers

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| npm | `npm completion` | stdout | Generates bash-style completion |
| yarn | No generation | N/A | Use oh-my-zsh plugin |
| pnpm | `pnpm completion zsh` | stdout | Alternative to npm |
| bun | `bun completions` | stdout | JavaScript runtime |

**Usage:**
```bash
npm completion > $(brew --prefix)/share/zsh/site-functions/_npm
pnpm completion zsh > $(brew --prefix)/share/zsh/site-functions/_pnpm
bun completions > $(brew --prefix)/share/zsh/site-functions/_bun
```

**Note:** npm's generated completion uses bash-style `compctl` instead of modern zsh completion system. System completion in `/usr/share/zsh/5.9/functions/_npm` is often better.

### Security & Authentication

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| op (1Password) | `op completion zsh` | stdout | 1Password CLI |
| age | No generation | N/A | Encryption tool |

**Usage:**
```bash
op completion zsh > $(brew --prefix)/share/zsh/site-functions/_op
```

### Build & Development Tools

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| mise | `mise completion zsh` | stdout | Dev tool version manager |
| just | `just --completions zsh` | stdout | Command runner |

**Usage:**
```bash
mise completion zsh > $(brew --prefix)/share/zsh/site-functions/_mise
just --completions zsh > $(brew --prefix)/share/zsh/site-functions/_just
```

### Web & API Tools

| Tool | Command | Output Location | Notes |
|------|---------|-----------------|-------|
| httpie | No generation | N/A | Use system completion |
| curl | No generation | N/A | Use system completion |
| jq | No generation | N/A | Use system or zsh-completions plugin |

## Tools WITHOUT Completion Generation

These popular tools do NOT have built-in completion generation and rely on system completions or third-party sources:

### Programming Language Tools
- python, node, ruby, go, rustc (use rustup instead)
- ruff, black, mypy, pytest (Python tools)
- eslint, prettier (JavaScript tools)

### Media Tools
- ffmpeg, imagemagick, vlc
- x264, x265, lame

### Data Tools
- jq, yq (use zsh-completions plugin)
- sqlite3, postgresql client

### System Tools
- tmux (use oh-my-zsh plugin)
- ssh, rsync, tar, zip

## Generation Best Practices

### Save to Homebrew Location

Preferred approach for tools installed via Homebrew:

```bash
<tool> <completion-command> > $(brew --prefix)/share/zsh/site-functions/_<tool>
```

**Advantages:**
- Automatic discovery (Homebrew path already in fpath)
- Organized with other Homebrew completions
- Consistent location across machines

### Save to Custom Directory

Alternative for user-installed tools:

```bash
mkdir -p ~/.zsh/completions
<tool> <completion-command> > ~/.zsh/completions/_<tool>
```

Then add to `~/.zshrc`:

```zsh
fpath=(~/.zsh/completions $fpath)
```

### Completion File Naming

Always name completion files with leading underscore:

- ✅ `_rustup` - Correct
- ✅ `_cargo` - Correct
- ❌ `rustup.zsh` - Wrong, won't be discovered
- ❌ `cargo-completion` - Wrong, missing underscore

### Verify After Generation

```bash
# Check file was created
ls -lh $(brew --prefix)/share/zsh/site-functions/_rustup

# Rebuild cache
rm -f ~/.zcompdump* && exec zsh

# Test completion is loaded
whence -v _rustup
```

## Systematic Discovery Process

To discover all completion-capable tools on a system:

1. **List all installed binaries:**
```bash
ls /opt/homebrew/bin/ > ~/all-tools.txt
ls ~/.local/bin/ >> ~/all-tools.txt
ls ~/.cargo/bin/ >> ~/all-tools.txt
```

2. **Test each tool** with discovery patterns:
```bash
for tool in $(cat ~/all-tools.txt); do
  if $tool completion --help &>/dev/null; then
    echo "$tool: completion command available"
  fi
done
```

3. **Check help output:**
```bash
for tool in $(cat ~/all-tools.txt); do
  if $tool --help 2>&1 | grep -qi completion; then
    echo "$tool: mentions completion in help"
  fi
done
```

See `scripts/discover-completions.sh` for an automated version of this process.

## Completion Update Strategy

### When Tools Update

Regenerate completions after major version updates:

```bash
# After updating rustup
rustup self update
rustup completions zsh rustup > $(brew --prefix)/share/zsh/site-functions/_rustup

# After updating uv
brew upgrade uv
uv generate-shell-completion zsh > $(brew --prefix)/share/zsh/site-functions/_uv
```

### Automation

Create a post-update hook to regenerate completions:

```bash
# In ~/.zshrc or post-upgrade script
function update-completions() {
  rustup completions zsh rustup > $(brew --prefix)/share/zsh/site-functions/_rustup
  rustup completions zsh cargo > $(brew --prefix)/share/zsh/site-functions/_cargo
  uv generate-shell-completion zsh > $(brew --prefix)/share/zsh/site-functions/_uv
  starship completions zsh > $(brew --prefix)/share/zsh/site-functions/_starship
  atuin gen-completions --shell zsh > $(brew --prefix)/share/zsh/site-functions/_atuin
  rm -f ~/.zcompdump*
  echo "Completions regenerated. Restart shell to load."
}
```

## Reference: All Tested Commands

Quick reference of exact commands that work:

```bash
# Rust ecosystem (via rustup)
rustup completions zsh rustup > _rustup
rustup completions zsh cargo > _cargo

# Python tools
uv generate-shell-completion zsh > _uv
pipx completions > _pipx
pdm completion zsh > _pdm

# Shell tools
starship completions zsh > _starship
atuin gen-completions --shell zsh > _atuin

# File tools
rclone completion zsh - > _rclone
fclones complete zsh > _fclones

# Git tools
gh completion -s zsh > _gh

# Package managers
pnpm completion zsh > _pnpm
bun completions > _bun

# Security
op completion zsh > _op

# Build tools
mise completion zsh > _mise
just --completions zsh > _just
```
