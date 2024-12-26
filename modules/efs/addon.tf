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

# EFS CSI Driver Role 생성
resource "aws_iam_role" "efs_csi_driver_role" {
  name               = "${var.application}-${var.environment}-efs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_role_assume_role_policy.json

  tags = {
    "ServiceAccount"          = "efs-csi-controller-sa"
    "ServiceAccountNameSpace" = "kube-system"
  } 
}

# Policy를 Role에 부여
resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver_role.name
}

# EFS CSI Driver Addon 생성
resource "aws_eks_addon" "aws_efs_csi_driver" {
  cluster_name  = var.cluster_name
  addon_name    = "aws-efs-csi-driver"
  addon_version = "v2.1.0-eksbuild.1"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  service_account_role_arn = aws_iam_role.efs_csi_driver_role.arn

  preserve = true

  tags = {
    "eks_addon" = "aws-efs-csi-driver"
  }
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.37.0-eksbuild.1" 
  service_account_role_arn = var.ebs_csi_role_arn
}