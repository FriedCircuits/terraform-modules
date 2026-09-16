output "builder_names" {
  description = "Builder names. This is what a workflow passes to `docker/setup-buildx-action` as `name`."
  value       = keys(local.builders)
}

output "stateful_set_names" {
  description = "The StatefulSet per builder. buildx appends `0` to the builder name, so these differ."
  value       = { for name, _ in local.builders : name => "${name}0" }
}
