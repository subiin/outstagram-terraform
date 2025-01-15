# outstagram-terraform

## 실행 방법
Outstagram 프로젝트에 필요한 AWS 리소스를 생성하는 Terraform입니다.

- environments : 개발/운영 환경
- modules : VPC, EKS 등의 AWS 리소스

프로비저닝하고자 하는 환경(dev 혹은 prd)별 디렉토리로 접근하여 "terraform apply -var-file=[환경].tfvars"를 실행하면 해당 환경에 따라 AWS 리소스가 생성됩니다.

## VPC
### 주요 특징
- VPC CIDR는 10.10.0.0/16이며, 서울 리전에 두 개의 가용 영역을 배치합니다.

  | |Private subnet|Public subnet|
  |------|---|---|
  |ap-northeast2a|10.10.1.0/24|10.10.3.0/24|
  |ap-northeast2b|10.10.2.0/24|10.10.4.0/24|

- NAT 게이트웨이를 한 개만 생성하여 모든 프라이빗 서브넷에서 동일한 NAT 게이트웨이를 공유합니다.

### 구성 내역
- 서브넷 생성
  - cidrsubnet 함수를 이용하여 CIDR 블록을 기준으로 서브넷을 생성합니다.
  ```
  # modules/vpc/main.tf
  
  private_subnets = ["${cidrsubnet(var.vpc_cidr, 8, 1)}", "${cidrsubnet(var.vpc_cidr, 8, 2)}"]
  public_subnets  = ["${cidrsubnet(var.vpc_cidr, 8, 3)}", "${cidrsubnet(var.vpc_cidr, 8, 4)}"]
  ```

## EKS
### 주요 특징
- API server endpoint access를 Public and private으로 설정합니다.
- 특정 CIDR 범위에서만 클러스터 엔드포인트의 public 접근을 허용합니다.
- 추후 kubernetes manifests를 생성하기 위해 로컬에 kubeconfig 파일을 생성합니다.
  
### 구성 내역
- VPC의 Outputs을 이용한 EKS 클러스터의 네트워크 설정
    - modules/vpc에서 VPC ID와 Subnet ID를 출력값으로 정의하는 outputs.tf를 생성합니다.
      ```
      # modules/vpc/outputs.tf

      output "vpc_id" {
        description = "VPC Id"
        value = module.vpc.vpc_id
      }
      
      output "private_subnet_ids" {
        description = "List of cidr_blocks of private subnets"
        value = module.vpc.private_subnets
      }
      ```
    - modules/eks에서 VPC ID와 Subnet ID를 인자로 받아 EKS 클러스터를 생성합니다.
      ```
      # modules/eks/main.tf

      module "eks" {
        vpc_id                   = var.vpc_id
        subnet_ids               = var.subnet_ids
      }
      ```
    - environments/dev에서 VPC 모듈의 출력값을 EKS 모듈에 전달합니다.
      ```
      # environments/dev/main.tf

      module "dev_eks" {
        source           = "../../modules/eks"
        vpc_id           = module.dev_vpc.vpc_id
        subnet_ids       = module.dev_vpc.private_subnet_ids
      }
      ```

- 특정 CIDR 범위에서의 클러스터 엔드포인트의 공개 접근 허용
    - Public access source allowlist를 설정하여 클러스터에 접근 가능한 ip 대역을 제한합니다.
      ```
      # modules/eks/main.tf

      module "eks" {
        cluster_endpoint_public_access  = true
        cluster_endpoint_private_access = true
      
        cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
      }
      ```
    - ip가 유동적인 경우를 대비하여 별도의 tfvars 파일로 쉽게 설정합니다.
      ```
      # environments/dev/main.tf

      module "dev_eks" {
        cluster_endpoint_public_access_cidrs = var.public_access_cidrs
      }
      
      
      # environments/dev/variables.tf
      
      variable "public_access_cidrs" {
        description = "List of subnet IDs where EKS worker nodes will be deployed"
        type        = list(string)
      }
      
      
      # environments/dev/dev.tfvars
      
      public_access_cidrs = ["[PUBLIC_IP_CIDR]"]
      ```

- 로컬에 kubeconfig 파일 생성
    - kubernetes Provider를 이용하여 kubernetes 리소스를 배포하려면 kubeconfig가 필요합니다. 이를 위해 local_file로 kubeconfig 파일을 로컬에 생성하여, 추후 kubernetes 리소스 생성에 사용합니다.
    
      - kubeconfig 템플릿을 생성합니다.
        ```
        # modules/eks/kubeconfig.tmpl

        apiVersion: v1
        clusters:
        - cluster:
            server: ${cluster_endpoint}
            certificate-authority-data: ${cluster_ca}
          name: ${cluster_arn}
        contexts:
        - context:
            cluster: ${cluster_arn}
            user: ${cluster_arn}
          name: ${cluster_arn}
        current-context: ${cluster_arn}
        kind: Config
        preferences: {}
        users:
        - name: ${cluster_arn}
          user:
            exec:
              apiVersion: client.authentication.k8s.io/v1beta1
              command: aws
              args:
                - --region
                - ap-northeast-2
                - eks
                - get-token
                - --cluster-name
                - ${cluster_name}
                - --output
                - json
        ```
      - 템플릿을 이용하여 kubeconfig를 로컬에 생성합니다.
        ```
        # modules/eks/main.tf

        resource "local_file" "kubeconfig" {
          filename = "${path.module}/kubeconfig"
          content  = templatefile("${path.module}/kubeconfig.tmpl", {
            cluster_endpoint = module.eks.cluster_endpoint,
            cluster_name     = module.eks.cluster_name,
            cluster_arn      = module.eks.cluster_arn,
            cluster_ca       = module.eks.cluster_certificate_authority_data
          })
        }
        ```
      - 템플릿을 바탕으로 kubeconfig 파일이 로컬에 생성됩니다.

## EFS
### 주요 특징
- 가용 영역(AZ)에 상관 없이 이미지 저장을 위해 EFS를 사용합니다.
- 각 가용 영역에서 EFS를 연결하기 위한 Mount targets을 생성합니다.
- VPC의 Private 서브넷에서만 NFS 트래픽을 허용합니다.
- IRSA 구성 후 EFS CSI Driver(EKS Add-on)를 설치합니다.
  
### 구성 내역
- Mount targets 설정
    - EFS 파일 시스템을 AWS 서브넷과 연결하기 위해 마운트 타겟을 지정합니다.
      ```
      # modules/efs/main.tf

      module "efs" {
      
        mount_targets = {
          "ap-northeast-2a" = {
            subnet_id = element(var.subnet_ids, 0)
          }
          "ap-northeast-2b" = {
            subnet_id = element(var.subnet_ids, 1)
          }
        }
      ```
    - Private Subnets에만 마운트하기 위해 VPC 모듈의 private_subnet_ids outputs 값을 가져옵니다.
      ```
      # environments/dev/main.tf

      module "dev_efs" {
        source                               = "../../modules/efs"
        depends_on                           = [module.dev_eks]
        subnet_ids                           = module.dev_vpc.private_subnet_ids
      }
      ```
      
- EFS CSI Driver(EKS Add-on) 설치
    - EKS 클러스터에서 EFS 파일시스템을 사용하도록 EFS CSI Driver를 설치합니다.
      - IRSA 구성
        - Trust entities 설정
          ```
          # modules/efs/addon.tf

          data "aws_iam_policy_document" "efs_csi_role_assume_role_policy" {
            statement {
              sid     = ""
              effect  = "Allow"
              actions = ["sts:AssumeRoleWithWebIdentity"]
          
              condition {
                test     = "StringEquals"
                variable = "${replace(var.cluster_oidc_issuer_url,"https://", "")}:aud"
                values   = ["sts.amazonaws.com"]
              }
          
              condition {
                test     = "StringEquals"
                variable = "${replace(var.cluster_oidc_issuer_url,"https://", "")}:sub"
                values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
              }
          
              principals {
                type        = "Federated"
                identifiers = [var.oidc_provider_arn]
              }
            }
          }
          ```
        - EFS CSI Driver의 IAM Role을 생성
          ```
          # modules/efs/addon.tf

          resource "aws_iam_role" "efs_csi_driver_role" {
            name               = "${var.application}-${var.environment}-efs-csi-role"
            assume_role_policy = data.aws_iam_policy_document.efs_csi_role_assume_role_policy.json
          
            tags = {
              "ServiceAccount"          = "efs-csi-controller-sa"
              "ServiceAccountNameSpace" = "kube-system"
            } 
          }
          ```
        - Policy 부여
          ```
          # modules/efs/addon.tf

          resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy_attach" {
            policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
            role       = aws_iam_role.efs_csi_driver_role.name
          }
          ```
      - EKS Add-ons 설치
        ```
        # modules/efs/addon.tf

        resource "aws_eks_addon" "aws_efs_csi_driver" {
          cluster_name  = var.cluster_name
          addon_name    = "aws-efs-csi-driver"
          addon_version = "v2.1.0-eksbuild.1"
        }
        ```

- Kubectl provider를 이용한 kubernetes 리소스(StorageClass) 생성
    - kubeconfig가 필요한 kubernetes Provider와 달리, 의존성이 없는 kubectl Provider를 이용하여 kubernetes 리소스인 StorageClass를 AWS 리소스가 만들어질 때 한 번에 생성합니다.
      - 먼저 Provider를 설정합니다.
        ```
        # environments/dev/providers.tf

        terraform {
          required_providers {
            kubectl = {
              source  = "gavinbunney/kubectl"
              version = ">= 1.10.0"
            }
          }
        }
        
        provider "kubectl" {
          host                   = module.dev_eks.cluster_endpoint
          cluster_ca_certificate = base64decode(module.dev_eks.cluster_certificate_authority_data)
          token                  = data.aws_eks_cluster_auth.main.token
          load_config_file       = false
        }
        ```
      - EFS의 ID를 가져와 kubectl_manifest를 생성합니다.
        ```
        # modules/efs/sc.tf

        data "aws_efs_file_system" "efs" {
          file_system_id = module.efs.id
        }
        
        resource "kubectl_manifest" "efs_storage_class" {
          yaml_body = <<YAML
            apiVersion: storage.k8s.io/v1
            kind: StorageClass
            metadata:
              name: efs-sc
            provisioner: efs.csi.aws.com
            parameters:
              provisioningMode: efs-ap
              fileSystemId: "${data.aws_efs_file_system.efs.id}"
              directoryPerms: "700"
          YAML
        }
        ```

## RDS
### 주요 특징
- Subnet group을 생성하여 RDS 인스턴스가 배치될 서브넷의 집합을 정의합니다.
- EKS 클러스터가 위치한 VPC에서 오는 MySQL 트래픽을 허용합니다.
- ASM(AWS Secrets Manager)을 이용해 password를 자동 변경합니다.
  
### 구성 내역
- MySQL 트래픽을 허용하는 Security Group 생성
    - EKS 클러스터가 위치한 VPC에서 오는 MySQL 트래픽을 허용합니다.
      - Security Group 생성
        ```
        # modules/rds-dev/sg.tf

        module "rds_security_group" {
          vpc_id      = var.vpc_id
        
          ingress_with_cidr_blocks = [
            {
              from_port   = 3306
              to_port     = 3306
              protocol    = "tcp"
              description = "Allow MySQL traffic from EKS"
              cidr_blocks = var.vpc_cidr_block
            }
          ]
        }
        ```
      - 생성한 Security Group 참조
        ```
        # modules/rds-dev/main.tf

        module "db" {
        
          vpc_security_group_ids = [module.rds_security_group.security_group_id]
        }
        ```
        
- ASM(AWS Secrets Manager)을 이용한 Password 자동 변경(운영 환경)
    - 보안을 높이기 위해 주기적으로 DB Password를 자동으로 변경합니다.
      - ASM(AWS Secrets Manager) 설정
        ```
        # modules/rds-prd/asm.tf

        resource "aws_secretsmanager_secret_rotation" "this" {
          secret_id          = var.secret_arn
          rotate_immediately = var.rotate_immediately
        
          rotation_rules {
            automatically_after_days = var.automatically_after_days
            duration                 = var.duration
            schedule_expression      = var.schedule_expression
          }
        }
        ```
      - RDS가 Secrets Manager에서 Password를 관리할 수 있도록 manage_master_user_password 값을 true로 설정합니다.
        ```
        # modules/rds-prd/main.tf

        module "db" {
        
          manage_master_user_password = true
        }
        ```

## S3
### 주요 특징
- Loki에서 사용하는 버킷을 생성하여 로그 저장과 관리를 합니다.
- S3 버전 관리를 사용하여 버킷에 저장된 모든 버전의 객체를 모두 보존, 검색 및 복원할 수 있도록 합니다.
  
### 구성 내역
- versioning 활성화
    - versioning 옵션을 활성화하여 버전 관리를 합니다.
      ```
      # modules/s3/main.tf

      module "s3_bucket" {
      
        versioning = {
          enabled = true
        }
      }
      ```
      
## Route53 & ACM
### 주요 특징
- Route53에서 Public hosted zone을 생성하여 각종 Records를 관리합니다.
- ACM에서 자동으로 도메인의 SSL/TLS 인증서를 발급하고 배포합니다.
  
### 구성 내역
- Public hosted zone 생성
    - Route53에서 Public hosted zone을 생성합니다.
      - Public hosted zone 생성합니다.
        ```
        # modules/route53/main.tf

        module "zones" {
        
          zones = var.zone_names
        }
        ```
        ```
        # environments/dev/main.tf

        module "dev_route53" {
          source                               = "../../modules/route53"
          zone_names                           = var.zone_names
        }
        ```

- 인증서 발급
    - ACM에서 자동으로 도메인의 SSL/TLS 인증서를 발급하고 배포합니다.
      - 검증 방법을 DNS로 하여 도메인 정보를 설정합니다.
        ```
        # modules/acm/main.tf

        module "acm" {
        
          domain_name  = var.domain_name
          zone_id      = var.zone_id
        
          validation_method = var.validation_method    # DNS
        
          subject_alternative_names = var.subject_alternative_names
        }
        ```
        ```
        # environments/dev/main.tf

        module "dev_acm" {
          source                               = "../../modules/acm"
          depends_on                           = [module.dev_route53]
          domain_name                          = var.domain_name
          zone_id                              = module.dev_route53.route53_zone_zone_id
          validation_method                    = var.validation_method
          subject_alternative_names            = var.subject_alternative_names
        }
        ```
        
## ECR
### 주요 특징
- 각 애플리케이션 서버별로 ECR 리포지토리를 생성합니다.
- 각 ECR 리포지토리별로 특정 tag를 가진 이미지만 푸시가 가능합니다.
  
### 구성 내역
- ECR 리포지토리 생성
    - 특정 tag로 시작하는 이미지만 푸시가 가능하도록 tagPrefixList 설정합니다.
      ```
      # modules/ecr/main.tf

      module "ecr" {
      
        repository_lifecycle_policy = jsonencode({
          rules = [
            {
              rulePriority = 1,
              description  = "Keep last 30 images",
              selection = {
                tagStatus     = "tagged",
                tagPrefixList = ["${var.tag}"],
                countType     = "imageCountMoreThan",
                countNumber   = 30
              },
              action = {
                type = "expire"
              }
            }
          ]
        })
      }
      ```
    - for_each로 각 리포지토리 이름을 생성하고 tag를 설정합니다.
      ```
      # environments/dev/main.tf

      module "dev_ecr" {
        source                               = "../../modules/ecr"
        for_each                             = var.ecr_repositories
        repository_name                      = each.key
        tag                                  = each.value
      }
      
      
      # environments/dev/virables.tf
      
      variable "ecr_repositories" {
        description = "List of ECR repositories to create with their tags"
        type = map(string)
        default = {
          "feed-server"     = "f_"
          "image-server"    = "i_"
          "sns-frontend"    = "s_"
          "timeline-server" = "t_"
          "user-server"     = "u_"
        }
      }
      ```

## IAM
### 주요 특징
- EKS 클러스터에서 AWS Load Balancer Controller와 External DNS에 필요한 IAM Role을 생성하고 IRSA(IAM Role for Service Accounts)를 설정합니다.
- GitHub Actions 워크플로우가 AWS 리소스에 접근할 수 있도록 OIDC(OpenID Connect)를 통해 GitHub Actions와 AWS의 IAM를 연동합니다.

### 구성 내역
- AWS Load Balancer Controller와 External DNS
    - AWS EKS 클러스터에서 필요한 IAM Role을 생성하고 IRSA를 설정합니다.
      ```
      # modules/eks/irsa.tf

      # AWS Load Balancer Controller IRSA
      module "load_balancer_controller_irsa_role" {
        source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
      
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
      
        attach_external_dns_policy    = true
        external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${var.secret_hosted_zone_id}"]
      
        oidc_providers = {
          oidc_provider = {
            provider_arn               = var.oidc_provider_arn
            namespace_service_accounts = ["kube-system:external-dns"]
          }
        }
      }
      ```
    - GitHub Actions의 OIDC 토큰을 AWS에서 신뢰하고 IAM 역할을 Assume할 수 있도록 설정합니다.
      ```
      # modules/iam/main.tf

      module "iam_github_oidc_provider" {
        source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
      
        url       = "https://token.actions.githubusercontent.com"
        client_id_list = [
          "sts.amazonaws.com",
        ]
      }
      
      module "iam_github_oidc_role" {
        source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
      
        audience = "sts.amazonaws.com"
        subjects = var.subjects
      
        policies = {
          ecrbuilds = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
        }
      }
      ```
    - 결과
