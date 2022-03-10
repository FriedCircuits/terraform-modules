output "groups" {
  value =[for value in jumpcloud_user_group.groups : {(value.name)=value.id}]
}

output "users" {
  value = [for value in jumpcloud_user.users : {(value.username)=value.id}]
}
