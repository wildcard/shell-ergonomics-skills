# Zsh Completions Configuration
# Add this to your ~/.zshrc BEFORE source $ZSH/oh-my-zsh.sh

# ============================================================================
# FPATH CONFIGURATION (Must come before oh-my-zsh.sh)
# ============================================================================

# zsh-completions plugin (200+ additional completions)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# Homebrew completions (works on Apple Silicon and Intel)
if type brew &>/dev/null; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
fi

# Custom user completions (highest priority)
fpath=(~/.zsh/completions $fpath)

# ============================================================================
# LOAD OH MY ZSH (compinit runs here automatically)
# ============================================================================

source $ZSH/oh-my-zsh.sh

# ============================================================================
# POST-LOAD: Tool Initialization (includes completions)
# ============================================================================

# Starship prompt (includes completion)
if type starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Zoxide directory jumper (includes completion)
if type zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# Atuin shell history (includes completion)
if type atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# ============================================================================
# COMPLETION GENERATION (run once to create files)
# ============================================================================
# Uncomment and run to generate completions, then comment out again.
# Or use examples/generate-completions.sh instead.

# mkdir -p ~/.zsh/completions
#
# if type rustup &>/dev/null; then
#   rustup completions zsh rustup > ~/.zsh/completions/_rustup
#   rustup completions zsh cargo > ~/.zsh/completions/_cargo
# fi
#
# if type uv &>/dev/null; then
#   uv generate-shell-completion zsh > ~/.zsh/completions/_uv
# fi
#
# if type fclones &>/dev/null; then
#   fclones complete zsh > ~/.zsh/completions/_fclones
# fi
#
# if type op &>/dev/null; then
#   op completion zsh > ~/.zsh/completions/_op
# fi

# ============================================================================
# VERIFICATION COMMANDS
# ============================================================================
# Run these after changes to verify completions are working:
#
# # Rebuild cache
# rm -f ~/.zcompdump* && exec zsh
#
# # Check if completion is loaded
# whence -v _brew
# whence -v _rustup
# whence -v _cargo
#
# # View current fpath
# echo $fpath | tr " " "\n"
#
# # List all available completions
# ls $(brew --prefix)/share/zsh/site-functions/_*
