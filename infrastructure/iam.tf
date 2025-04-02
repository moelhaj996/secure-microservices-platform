# CI/CD IAM User
resource "aws_iam_user" "cicd" {
  name = "github-actions-cicd"
  path = "/system/"

  tags = {
    Description = "IAM user for GitHub Actions CI/CD"
    Project     = var.project_name
  }
}

# Access key for the CI/CD user
resource "aws_iam_access_key" "cicd" {
  user = aws_iam_user.cicd.name
}

# Policy for CI/CD
resource "aws_iam_user_policy" "cicd_policy" {
  name = "github-actions-cicd-policy"
  user = aws_iam_user.cicd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-terraform-state",
          "arn:aws:s3:::${var.project_name}-terraform-state/*"
        ]
      }
    ]
  })
}

# Output the access key and secret
output "cicd_access_key" {
  value     = aws_iam_access_key.cicd.id
  sensitive = false
}

output "cicd_secret_key" {
  value     = aws_iam_access_key.cicd.secret
  sensitive = true
} 