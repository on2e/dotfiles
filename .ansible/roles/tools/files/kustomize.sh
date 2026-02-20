# shellcheck disable=SC1090,SC1091
. <(kustomize completion bash)
alias kz=kustomize
complete -o default -F __start_kustomize kz
