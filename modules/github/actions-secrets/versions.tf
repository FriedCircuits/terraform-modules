terraform {
  required_version = ">= 1.0"

  required_providers {
    github = {
      source = "integrations/github"
      # 5.19 is where github_actions_variable was added.
      version = ">= 5.19"
    }
  }
}
