# modules/eks/main.tf

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_name    = "${var.application}-${var.environment}-cluster"
  cluster_version = var.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # 클러스터 엔드포인트의 공개 접근을 허용할 CIDR 범위 설정
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_group_defaults = {
    instance_types = ["c4.xlarge"]
  }

  eks_managed_node_groups = {
    new_node_group = {
      instance_types = ["c4.xlarge"]

      min_size     = 3
      max_size     = 3
      desired_size = 3
    }
  }

  # 클러스터 생성자에게 관리자 권한 부여
  enable_cluster_creator_admin_permissions = true
}

# 로컬에 kubeconfig 파일 생성
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = templatefile("${path.module}/kubeconfig.tmpl", {
    cluster_endpoint = module.eks.cluster_endpoint,
    cluster_name     = module.eks.cluster_name,
    cluster_arn      = module.eks.cluster_arn,
    cluster_ca       = module.eks.cluster_certificate_authority_data
  })

  depends_on = [module.eks]
}


