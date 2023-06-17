alias showAlias='cat ~/.bash_aliases'
alias execPhx='sudo nerdctl exec -it --namespace phoenix'
alias lsPhx='sudo nerdctl ps --namespace phoenix'
alias prunePhx='sudo nerdctl container prune --namespace phoenix --force'
alias startPhx='sudo nerdctl container start --namespace phoenix'
alias stopPhx="sudo nerdctl stop --namespace phoenix"

stopAllPhx() {
    local container_ids=$(lsPhx -q)
    for id in $container_ids; do
        stopPhx "$id"
    done
}

wipePhx() {
    stopAllPhx
    prunePhx
}

#sudo env "PATH=$PATH" go test ./internal/k9sclient/client_integration_test.go -v -run TestStartContainerWithAllGPUs

