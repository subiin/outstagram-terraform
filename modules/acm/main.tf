# modules/acm/main.tf

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = var.domain_name
  zone_id      = var.zone_id

  validation_method = var.validation_method

  subject_alternative_names = var.subject_alternative_names

  wait_for_validation = true

  tags = {
    Name = var.domain_name
  }
}