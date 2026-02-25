#!/usr/bin/env bash
# ~/.bashrc — interactive bash shell configuration
# Managed by dotfiles repo; symlinked into $HOME by install.sh.
# Edit the source in the repo — changes take effect immediately via the symlink.

# ---------------------------------------------------------------------------
# Non-interactive guard
# If this shell is not interactive (e.g. a script sourcing .bashrc), exit now.
# ---------------------------------------------------------------------------
[[ $- == *i* ]] || return

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTSIZE=10000          # Number of commands kept in memory
HISTFILESIZE=20000      # Number of commands kept on disk
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "   # Timestamp each entry

# ignoredups — skip duplicate of previous command
# erasedups  — remove all earlier duplicates across the whole history
HISTCONTROL=ignoredups:erasedups

# Append to history file on exit rather than overwriting
shopt -s histappend

# ---------------------------------------------------------------------------
# Shell options
# ---------------------------------------------------------------------------
shopt -s checkwinsize   # Update LINES and COLUMNS after each command
shopt -s globstar       # Enable ** recursive glob pattern

# ---------------------------------------------------------------------------
# Prompt (PS1)
# ---------------------------------------------------------------------------
# Format: [HH:MM:SS user@host:~/path]$
# Colours: time=cyan, user@host=bold green, path=bold blue
_ps1_colour_reset='\[\033[0m\]'
_ps1_time='\[\033[0;36m\]'          # cyan
_ps1_userhost='\[\033[1;32m\]'      # bold green
_ps1_path='\[\033[1;34m\]'          # bold blue

PS1="${_ps1_time}[\t]${_ps1_reset} ${_ps1_userhost}\u@\h${_ps1_colour_reset}:${_ps1_path}\w${_ps1_colour_reset}\$ "

# Clean up PS1 helper vars
unset _ps1_colour_reset _ps1_time _ps1_userhost _ps1_path

# ---------------------------------------------------------------------------
# Colour support
# ---------------------------------------------------------------------------
# Enable colour for ls
if command -v dircolors &>/dev/null; then
  if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
fi

alias ls='ls --color=auto'

# ---------------------------------------------------------------------------
# PATH additions
# ---------------------------------------------------------------------------
# ~/bin and ~/.local/bin — user-installed scripts and pip-installed tools
[[ -d "$HOME/bin" ]]        && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# Source aliases
# ---------------------------------------------------------------------------
if [[ -f ~/.bash_aliases ]]; then
  # shellcheck source=/dev/null
  source ~/.bash_aliases
fi

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
# Source bash-completion if available (installed by default on Ubuntu 22.04)
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
fi
