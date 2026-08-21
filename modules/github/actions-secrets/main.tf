provider "github" {
  token = var.github_token
}

data "github_actions_public_key" "public_key" {
  repository = var.repository
}

resource "github_actions_secret" "secret" {
  for_each    = var.secrets
  repository  = var.repository
  secret_name = each.key
  value       = each.value
}

resource "github_actions_variable" "variable" {
  for_each      = var.variables
  repository    = var.repository
  variable_name = each.key
  value         = each.value
}

resource "github_actions_secret" "aws_key_id" {
  count       = var.create_aws_iam_user == true ? 1 : 0
  repository  = var.repository
  secret_name = "AWS_ACCESS_KEY_ID"
  value       = aws_iam_access_key.github[0].id
}

resource "github_actions_secret" "aws_key" {
  count       = var.create_aws_iam_user == true ? 1 : 0
  repository  = var.repository
  secret_name = "AWS_SECRET_ACCESS_KEY"
  value       = aws_iam_access_key.github[0].secret
}
# https://terragrunt.gruntwork.io/docs/features/aws-auth/
data "aws_iam_policy_document" "github" {
  count = var.create_aws_iam_user == true ? 1 : 0
  statement {
    sid = "AllowAllS3ActionsOnSpecifiedTerragruntBucket"
    actions = [
      "*"
      # Couldn't get terragrunt working with the list below from the documentation.
      # "s3:ListBucket",
      # "s3:GetBucketVersioning",
      # "s3:GetObject",
      # "s3:GetBucketAcl",
      # "s3:GetBucketLogging",
      # "s3:CreateBucket",
      # "s3:PutObject",
      # "s3:PutBucketPublicAccessBlock",
      # "s3:PutBucketTagging",
      # "s3:PutBucketPolicy",
      # "s3:PutBucketVersioning",
      # "s3:PutEncryptionConfiguration",
      # "s3:PutBucketAcl",
      # "s3:PutBucketLogging"
    ]
    resources = ["arn:aws:s3:::${var.terraform_bucket_name}"]
  }
  statement {
    sid = "AllowGetAndPutS3ActionsOnSpecifiedTerragruntBucketPath"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${var.terraform_bucket_name}/*"]
  }
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [var.terraform_dynamodb_table_arn]
  }
}

resource "aws_iam_user" "github" {
  count = var.create_aws_iam_user == true ? 1 : 0
  name  = var.aws_iam_user_name
  tags  = var.tags
}

resource "aws_iam_access_key" "github" {
  count = var.create_aws_iam_user == true ? 1 : 0
  user  = aws_iam_user.github[0].name
}

resource "aws_iam_user_policy" "github" {
  count = var.create_aws_iam_user == true ? 1 : 0
  name  = "terraform-backend"
  user  = aws_iam_user.github[0].name

  policy = data.aws_iam_policy_document.github[0].json
}

resource "aws_iam_user_policy" "custom" {
  count = var.create_aws_iam_user == true ? 1 : 0
  name  = "custom-policies"
  user  = aws_iam_user.github[0].name

  policy = data.aws_iam_policy_document.custom[0].json
}
data "aws_iam_policy_document" "custom" {
  count = var.create_aws_iam_user == true ? 1 : 0
  dynamic "statement" {
    for_each = { for statement in var.aws_iam_custom_policies : statement.sid => statement }
    content {
      sid       = statement.value.sid
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# ---------------------------------------------------------------------------
# Deployment environments
# ---------------------------------------------------------------------------

locals {
  # Flattened so each secret and variable is its own resource. Keyed by
  # environment and name together, because the same name legitimately appears in
  # several environments -- that is the point of them.
  environment_secrets = merge([
    for env, cfg in var.environments : {
      for name, value in cfg.secrets : "${env}/${name}" => {
        environment = env
        name        = name
        value       = value
      }
    }
  ]...)

  environment_variables = merge([
    for env, cfg in var.environments : {
      for name, value in cfg.variables : "${env}/${name}" => {
        environment = env
        name        = name
        value       = value
      }
    }
  ]...)
}

resource "github_repository_environment" "environment" {
  for_each = var.environments

  repository  = var.repository
  environment = each.key

  wait_timer          = each.value.wait_timer
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review

  # Billing-gated on private repositories. Leaving reviewer ids unset omits the
  # block entirely, so the environment is created rather than rejected with 422.
  dynamic "reviewers" {
    for_each = (
      try(length(each.value.reviewer_user_ids), 0) > 0 ||
      try(length(each.value.reviewer_team_ids), 0) > 0
    ) ? [1] : []

    content {
      users = try(each.value.reviewer_user_ids, null)
      teams = try(each.value.reviewer_team_ids, null)
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.deployment_branch_policy != null ? [each.value.deployment_branch_policy] : []

    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }
}

resource "github_actions_environment_secret" "secret" {
  for_each = local.environment_secrets

  repository  = var.repository
  environment = github_repository_environment.environment[each.value.environment].environment
  secret_name = each.value.name
  value       = each.value.value
}

resource "github_actions_environment_variable" "variable" {
  for_each = local.environment_variables

  repository    = var.repository
  environment   = github_repository_environment.environment[each.value.environment].environment
  variable_name = each.value.name
  value         = each.value.value
}
