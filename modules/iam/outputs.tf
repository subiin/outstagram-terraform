# modules/iam/outputs.tf

output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = module.ebs_csi_irsa_role.iam_role_arn
}