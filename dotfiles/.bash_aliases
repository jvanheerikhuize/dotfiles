# ~/.bash_aliases — shell aliases
# Sourced by ~/.bashrc in interactive sessions.
# Managed by dotfiles repo; symlinked into $HOME by install.sh.

# ---------------------------------------------------------------------------
# Directory listing
# ---------------------------------------------------------------------------
alias ll='ls -alFh'     # Long listing, hidden files, classify, human-readable sizes
alias la='ls -A'        # List all (including hidden), excluding . and ..

# ---------------------------------------------------------------------------
# Coloured tools
# ---------------------------------------------------------------------------
alias grep='grep --color=auto'

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------
alias ..='cd ..'
alias ../..='cd ../..'

# ---------------------------------------------------------------------------
# Git shortcuts
# ---------------------------------------------------------------------------
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
