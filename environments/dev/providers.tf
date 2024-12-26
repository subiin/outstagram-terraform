# environments/dev/providers.tf

terraform {
  required_version = ">= 1.4"

  backend "s3" {
    bucket         = "outstagram-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "outstagram_terraform_state_lock"
    encrypt        = true
  }

  required_providers {
    kubectl = {
      source      = "gavinbunney/kubectl"
      version     = ">= 1.10.0"
    }
  }
}

locals {
  region          = "ap-northeast-2"
  service         = "outstagram"
  environment     = "dev"
}

data "aws_eks_cluster_auth" "main" {
  name = module.dev_eks.cluster_name
}

provider "aws" {
  region          = local.region

  default_tags {
    tags = {
      Terraform   = "true"
      Service     = local.service
      Environment = local.environment
    }
  }
}

provider "kubectl" {
  host                   = module.dev_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.dev_eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

# provider "kubernetes" {
#   config_path            = module.dev_eks.kubeconfig_path
# }