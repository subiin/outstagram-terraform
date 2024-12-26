# modules/efs/main.tf

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  name           = "${var.application}-${var.environment}-efs"
  encrypted      = true
  
  # 30일 후에 IA(Infrequent Access) 클래스로 전환
  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  attach_policy                      = true
  bypass_policy_lockout_safety_check = false

  # 각 가용 영역(AZ)에서 EFS를 연결하기 위한 마운트 타겟 생성
  mount_targets = {
    "ap-northeast-2a" = {
      subnet_id = element(var.subnet_ids, 0)
    }
    "ap-northeast-2b" = {
      subnet_id = element(var.subnet_ids, 1)                   
    }
  }

  # VPC 내에서만 private 서브넷에서의 NFS 트래픽을 허용
  security_group_description = "Outstagram EFS security group"
  security_group_vpc_id      = var.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.private_subnets_cidr_blocks
    }
  }

  enable_backup_policy = true

  create_replication_configuration = true
  replication_configuration_destination = {
    region = var.region
  }
}