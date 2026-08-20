variable "github_token" {
  description = "Github token with access to create actions secrets."
  type        = string
}

variable "repository" {
  description = "Repoistory to deploy secrets to."
  type        = string
}

variable "create_aws_iam_user" {
  description = "Create AWS IAM user with access to Terraform backend bucket. AWS keys are stored as github secrets."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for provider config. Used with terragrunt generated provider."
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "AWS account id for provider config. Used with terragrunt generated provider."
  type        = string
  default     = ""
}

variable "aws_iam_user_name" {
  description = "Name for AWS IAM User. This user when enabled creats sercrets or github runners to access Terraform backend S3 bucket."
  type        = string
  default     = "github-terraform-backend"
}

variable "aws_iam_custom_policies" {
  description = "Extra policy statements to add to IAM user."
  type = list(object({
    sid       = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "terraform_bucket_name" {
  description = "Terraform backend bucket name for IAM policy."
  type        = string
  default     = ""
}

variable "terraform_dynamodb_table_arn" {
  description = "Terraform backend dynamodb table arn for IAM policy."
  type        = string
  default     = ""
}

variable "tags" {
  description = "AWS tags for IAM user."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of secrets for github."
  type        = map(string)
}

variable "variables" {
  description = <<-EOT
    Map of Actions variables for the repository.

    Unlike secrets these are stored in plain text, readable through the API and
    the settings UI, and not masked in workflow logs. Use them for values that
    are configuration rather than credentials -- a bucket name, a region, a
    role ARN.
  EOT
  type        = map(string)
  default     = {}
}

variable "environments" {
  description = <<-EOT
    Deployment environments to create on the repository, each with its own
    secrets and variables, keyed by environment name.

    Environment-scoped values are the way to give one workflow a different role,
    account or region per environment without branching in YAML -- a job that
    declares `environment: staging` sees the staging values under the same
    names.

    Protection rules are a separate matter. reviewers, wait_timer and
    deployment_branch_policy are billing-gated on private repositories: on a
    Free plan the API answers 422 with "Please ensure the billing plan supports
    the required reviewers protection rule". They are optional here and unset by
    default so an environment can be created on any plan; set them only where
    the plan allows.
  EOT
  type = map(object({
    secrets   = optional(map(string), {})
    variables = optional(map(string), {})

    wait_timer          = optional(number)
    can_admins_bypass   = optional(bool)
    prevent_self_review = optional(bool)

    reviewer_user_ids = optional(list(number))
    reviewer_team_ids = optional(list(number))

    deployment_branch_policy = optional(object({
      protected_branches     = bool
      custom_branch_policies = bool
    }))
  }))
  default = {}
}
