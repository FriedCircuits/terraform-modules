variable "jumpcloud_org_id" {
  description = "JumpCloud Orginzation ID found in the console."
  type        = string
}

variable "jumpcloud_api" {
  description = "JumpCloud API key found in the console."
  type        = string
}

variable "groups" {
  description = "Map of groups to create."
  type        = any
}

variable "users" {
  description = "Map of users and their groups to create."
  type        = any
}
