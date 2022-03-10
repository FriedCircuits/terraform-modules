# JumpCloud User and Group Management Module

Using the JumpCloud provider this module will create users and groups, and assign them appropriately.


## Users and Groups Variable Format

```hcl
groups = ["group1", "group2"]

users = {
    user1 = {
      email     = "user1@example.com"
      lastname  = "smith"
      firstname = "john"
      groups    = ["group1","group2"]
      mfa       = true
    },
    user2 = {
      email     = "user2@example.com"
      lastname  = "smith"
      firstname = "jane"
      groups    = ["group1"]
      mfa       = false
    }
  }
}
```
