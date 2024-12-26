# modules/efs/sc.tf

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}

data "aws_efs_file_system" "efs" {
  file_system_id = module.efs.id
}

# StorageClass 생성
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