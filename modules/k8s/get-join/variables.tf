variable "k8s_control_config" {
  description = "Hostname/SSH User of K8S control plan node to get join command from. Assumes your private is deployed for `ssh_user`."
  type        = object({
    hostname = string
    ssh_user = string
  })
}
