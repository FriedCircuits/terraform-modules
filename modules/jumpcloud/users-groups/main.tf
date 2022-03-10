provider "jumpcloud" {
  org_id  = var.jumpcloud_org_id
  api_key = var.jumpcloud_api
}

resource "jumpcloud_user" "users" {
  for_each = var.users

  username   = each.key
  email      = each.value["email"]
  firstname  = title(each.value["firstname"])
  lastname   = title(each.value["lastname"])
  enable_mfa = each.value["mfa"]
}

resource "jumpcloud_user_group" "groups" {
  for_each = toset(var.groups)
  name     = each.value
}

locals {
  group_matrix = [ for user in keys(var.users) :
    setproduct([jumpcloud_user.users[user].id], [for group in var.users[user].groups : jumpcloud_user_group.groups[group].id] )
  ]
  group_flat = flatten([
    for sets in local.group_matrix : [
      for set in sets : {
        user  = set[0]
        group = set[1]
      }
    ]
  ])
}

resource "jumpcloud_user_group_membership" "members" {
  for_each = { for index, set in local.group_flat: index => set }
  user_id  = each.value.user
  group_id = each.value.group
}
