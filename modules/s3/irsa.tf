# modules/s3/irsa.tf

resource "aws_iam_policy" "loki_s3_role_policy" {
  name        = "AmazonS3EksLokiAccess"
  path        = "/"
  description = "Policy for Loki to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          "${module.s3_bucket.s3_bucket_arn}",
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role" "loki_s3_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = [var.oidc_provider_arn]
        },
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url,"https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(var.cluster_oidc_issuer_url,"https://", "")}:sub" = "system:serviceaccount:monitoring:loki"
          }
        }
      },
    ]
  })
  description           = "Role for Loki to access S3 bucket"
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "${var.application}-${var.environment}-loki-role"
  path                  = "/"
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy_attach" {
  policy_arn = aws_iam_policy.loki_s3_role_policy.arn
  role       = aws_iam_role.loki_s3_role.name
}