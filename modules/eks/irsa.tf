# modules/eks/irsa.tf

# AWS Load Balancer Controller IRSA
module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.application}-${var.environment}-lb-controller-role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    oidc_provider = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# External DNS IRSA
module "external_dns_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = "${var.application}-${var.environment}-external-dns-role"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${var.secret_hosted_zone_id}"]

  oidc_providers = {
    oidc_provider = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}