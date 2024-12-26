# # modules/route53/main.tf

module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  zones = var.zone_names
}
