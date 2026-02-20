# shellcheck disable=SC1090,SC1091
. <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
