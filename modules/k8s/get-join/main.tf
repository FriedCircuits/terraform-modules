
data "external" "k8s" {
  program = ["bash", "${path.module}/get_join.sh"]
  query   = var.k8s_control_config
}
