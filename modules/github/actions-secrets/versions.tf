terraform {
  required_version = ">= 1.0"

  required_providers {
    github = {
      source = "integrations/github"
      # 6.0 is where github_actions_secret gained `value`; the older
      # plaintext_value is deprecated.
      version = ">= 6.0"
    }
  }
}
