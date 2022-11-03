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
