# Load bash-completion if it exists and it is not already loaded system-wide
# (usually from /etc/bash.bashrc or /etc/profile.d/bash_completion.sh).
if [[ -z "${BASH_COMPLETION_VERSINFO-}" ]] \
  && [[ -r '/usr/share/bash-completion/bash_completion' ]]; then
  . '/usr/share/bash-completion/bash_completion'
fi
