provider "github" {
  token = var.github_token
}

data "github_actions_public_key" "public_key" {
  repository = var.repository
}

resource "github_actions_secret" "secret" {
  for_each        = var.secrets
  repository      = var.repository
  secret_name     = each.key
  plaintext_value = each.value
}

resource "github_actions_secret" "aws_key_id" {
  count           = var.create_aws_iam_user == true ? 1 : 0
  repository      = var.repository
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.github[0].id
}

resource "github_actions_secret" "aws_key" {
  count           = var.create_aws_iam_user == true ? 1 : 0
  repository      = var.repository
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.github[0].secret
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
      sid       = each.value.sid
      actions   = each.value.actions
      resources = each.value.resources
    }
  }
}
