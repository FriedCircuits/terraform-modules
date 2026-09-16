output "builder_names" {
  description = "Builder name per architecture. This is what a workflow passes to `docker/setup-buildx-action` as `name`."
  value       = local.builders
}

output "stateful_set_names" {
  description = "The StatefulSet per architecture. buildx appends `0` to the builder name, so these differ."
  value       = { for arch, name in local.builders : arch => "${name}0" }
}
