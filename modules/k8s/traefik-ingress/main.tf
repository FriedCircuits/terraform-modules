resource "helm_release" "k8s" {
  name       = "${var.name}-traefik-ingress"
  chart      = "${path.module}/traefik-ingress"
  namespace  = var.namespace

  set {
    name  = "namespace"
    value = var.namespace
  }
  set {
     name  = "name"
     value = var.name
  }
  set {
    name  = "certResolver"
    value = var.cert_resolver
  }
  set {
    name  = "host"
    value = var.host
  }
  set {
    name  = "serviceName"
    value = var.service
  }
  set {
    name  = "servicePort"
    value = var.service_port
  }
}
