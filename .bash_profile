# If not running bash, don't do anything
[ -n "${BASH_VERSION-}" ] || return 0

# Load sh-compatible shell configuration
if [[ -f "${HOME}/.profile" ]]; then
  . "${HOME}/.profile"
fi

# Load bash-specific configuration
if [[ -f "${HOME}/.bashrc" ]]; then
  . "${HOME}/.bashrc"
fi
