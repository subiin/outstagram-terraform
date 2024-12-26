# modules/ecr/main.tf

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${var.application}-${var.environment}-${var.repository_name}"

  create_repository = true

  # 태그 변경 허용
  repository_image_tag_mutability = "MUTABLE"

  # 이미지의 유지 관리 규칙을 정의
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