# environments/prd/main.tf

module "prd_vpc" {
  source                               = "../../modules/vpc"
  region                               = var.region
  application                          = var.application
  environment                          = var.environment
  vpc_cidr                             = var.vpc_cidr
}

module "prd_eks" {
  source                               = "../../modules/eks"
  application                          = var.application
  environment                          = var.environment
  vpc_id                               = module.prd_vpc.vpc_id
  subnet_ids                           = module.prd_vpc.private_subnet_ids
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs
  namespaces                           = var.namespaces
  oidc_provider_arn                    = module.prd_eks.oidc_provider_arn
  db_instance_address                  = module.prd_rds.db_instance_address
  secret_hosted_zone_id                = module.prd_route53.route53_zone_zone_id ##
}

module "prd_s3" {
  source                               = "../../modules/s3"
  environment                          = var.environment
  application                          = var.application
  cluster_oidc_issuer_url              = module.prd_eks.cluster_oidc_issuer_url
  oidc_provider_arn                    = module.prd_eks.oidc_provider_arn
}

module "prd_efs" {
  source                               = "../../modules/efs"
  depends_on                           = [module.prd_eks]
  environment                          = var.environment
  application                          = var.application
  region                               = var.region
  subnet_ids                           = module.prd_vpc.private_subnet_ids
  vpc_id                               = module.prd_vpc.vpc_id
  vpc_cidr_block                       = module.prd_vpc.vpc_cidr_block
  private_subnets_cidr_blocks          = module.prd_vpc.private_subnets_cidr_blocks
  cluster_name                         = module.prd_eks.cluster_name
  cluster_oidc_issuer_url              = module.prd_eks.cluster_oidc_issuer_url
  oidc_provider_arn                    = module.prd_eks.oidc_provider_arn
  ebs_csi_role_arn                     = module.prd_iam.iam_role_arn
}

module "prd_rds" {
  source                               = "../../modules/rds-prd"
  application                          = var.application
  environment                          = var.environment
  engine                               = var.engine
  engine_version                       = var.engine_version
  vpc_security_group_ids               = module.prd_vpc.default_security_group_id
  vpc_id                               = module.prd_vpc.vpc_id
  vpc_cidr_block                       = module.prd_vpc.vpc_cidr_block
  subnet_ids                           = module.prd_vpc.private_subnet_ids
  maintenance_window                   = var.maintenance_window
  backup_window                        = var.backup_window
  monitoring_interval                  = var.monitoring_interval
  secret_arn                           = module.prd_rds.db_instance_master_user_secret_arn
  rotate_immediately                   = var.rotate_immediately
  automatically_after_days             = var.automatically_after_days
  duration                             = var.duration
  schedule_expression                  = var.schedule_expression
}

module "prd_ecr" {
  source                               = "../../modules/ecr"
  application                          = var.application
  environment                          = var.environment
  for_each                             = var.ecr_repositories
  repository_name                      = each.key
  tag                                  = each.value
  subjects                             = var.subjects
}

module "prd_iam" {
  source                               = "../../modules/iam"
  application                          = var.application
  environment                          = var.environment
  subjects                             = var.subjects
  oidc_provider_arn                    = module.prd_eks.oidc_provider_arn
}

module "prd_route53" {
  source                               = "../../modules/route53"
  zone_names                           = var.zone_names
}

module "prd_acm" {
  source                               = "../../modules/acm"
  depends_on                           = [module.prd_route53]
  domain_name                          = var.domain_name
  zone_id                              = module.prd_route53.route53_zone_zone_id
  validation_method                    = var.validation_method
  subject_alternative_names            = var.subject_alternative_names
}