# If not running bash, don't do anything
[[ -n "${BASH_VERSION-}" ]] || return 0

if [[ -d "${HOME}/bin" ]] && [[ ":${PATH}:" != *":${HOME}/bin:"* ]]; then
  PATH="${HOME}/bin:${PATH}"
fi

if [[ -d "${HOME}/.local/bin" ]] \
  && [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
  PATH="${HOME}/.local/bin:${PATH}"
fi

if [[ -f "${HOME}/.bashrc" ]]; then
  . "${HOME}/.bashrc"
fi
