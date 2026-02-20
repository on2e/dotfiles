export NVM_DIR="${HOME}/.nvm"

if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
  . "${NVM_DIR}/nvm.sh"
fi

# shellcheck disable=SC1090,SC1091
if [[ -s "${NVM_DIR}/bash_completion" ]]; then
  . "${NVM_DIR}/bash_completion"
fi
