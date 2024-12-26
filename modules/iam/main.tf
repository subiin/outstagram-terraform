# modules/iam/main.tf

## GitHub Actions
# GitHub Actions에서 발급하는 OIDC 토큰을 AWS에서 신뢰하도록 OIDC 공급자를 설정
module "iam_github_oidc_provider" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  url       = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
}

# OIDC를 사용하여 GitHub Actions에서 AWS IAM 역할을 Assume할 수 있도록 설정
module "iam_github_oidc_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  name = "${var.application}-${var.environment}-github-actions-role"

  audience = "sts.amazonaws.com"
  subjects = var.subjects

  policies = {
    ecrbuilds = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  }
}

## EBS CSI Driver
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.application}-${var.environment}-ebs-csi-role"
  attach_ebs_csi_policy = true

  oidc_providers = {
    oidc_provider = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}