# ~/.bash_profile — login shell configuration
# Sourced by bash for login shells (SSH, TTY, and some display managers).
# Managed by dotfiles repo; symlinked into $HOME by install.sh.

# Delegate to .bashrc so that login and interactive shells share the same
# environment. Guard against .bashrc not existing (first boot, partial setup).
if [[ -f ~/.bashrc ]]; then
  # shellcheck source=/dev/null
  source ~/.bashrc
fi
