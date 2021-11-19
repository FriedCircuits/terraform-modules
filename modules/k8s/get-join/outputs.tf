output "k8s_join" {
    description = "Map of config values needed to join a kuberentes cluster."
    value       = data.external.k8s.result
    senstive    = true
}

output "full_join_command" {
    description = "Full command to join a worker node to kubernetes cluster."
    senstive    = true
    value       = "kubeadm join ${data.external.k8s.result.host} --token ${data.external.k8s.result.token} --discovery-token-ca-cert-hash ${data.external.k8s.result.cacerthash}"
}
