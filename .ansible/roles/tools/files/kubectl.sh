# shellcheck disable=SC1090,SC1091
. <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k

# Set KUBECONFIG environment variable
__dot_kubectl__kubeconfig_env() {
  # KUBECONFIG is set to a list of kubeconfig files located under ~/.kube as
  # follows:
  #   1. If ~/.kube is not a directory or does not contain any kubeconfig files
  #      (as defined by the convention in 2.) other than possibly the default
  #      kubeconfig file, ~/.kube/config, KUBECONFIG is not set.
  #   2. Any .yml or .yaml files directly under ~/.kube are sorted and combined
  #      into a colon-delimited list. If ~/.kube/config also exists, it is
  #      prepended to the list as its first entry.
  local kubeconfig

  [[ -d "${HOME}/.kube" ]] || return 0

  local -a kubeconfig_files
  readarray -d '' -t kubeconfig_files < <(find "${HOME}/.kube" -mindepth 1 -maxdepth 1 -type f -regex '.*\.ya?ml' -print0 | sort -z)
  (("${#kubeconfig_files[@]}")) || return 0

  if [[ -f "${HOME}/.kube/config" ]]; then
    kubeconfig="${HOME}/.kube/config"
  fi
  local f
  for f in "${kubeconfig_files[@]}"; do
    kubeconfig="${kubeconfig:+${kubeconfig}:}${f}"
  done

  export KUBECONFIG="${kubeconfig}"
}

__dot_kubectl__kubeconfig_env

unset -f __dot_kubectl__kubeconfig_env
