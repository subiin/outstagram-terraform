# modules/vpc/main.tf

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.application}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["${cidrsubnet(var.vpc_cidr, 8, 1)}", "${cidrsubnet(var.vpc_cidr, 8, 2)}"]
  public_subnets  = ["${cidrsubnet(var.vpc_cidr, 8, 3)}", "${cidrsubnet(var.vpc_cidr, 8, 4)}"]

  enable_nat_gateway = true
  # NAT 게이트웨이를 한 개만 생성하여 모든 프라이빗 서브넷에서 동일한 NAT 게이트웨이를 공유
  single_nat_gateway = true

  # EKS는 퍼블릭 서브넷을 외부 로드 밸런서(ALB, ELB)용 서브넷으로 인식
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  # EKS는 프라이빗 서브넷을 내부 로드 밸런서용으로 인식
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
