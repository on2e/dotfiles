if [[ -d "${HOME}/.krew/bin" ]] \
  && [[ ":${PATH}:" != *":${HOME}/.krew/bin:"* ]]; then
  PATH="${HOME}/.krew/bin:${PATH}"
fi
