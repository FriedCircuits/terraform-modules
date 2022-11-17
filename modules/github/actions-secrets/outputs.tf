output "github_public_key" {
  value = data.github_actions_public_key.public_key
}

output "aws_iam_user_arn" {
  value = try(aws_iam_user.github[0].arn, "no iam user")
}
