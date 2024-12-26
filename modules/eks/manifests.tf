# modules/eks/manifests.tf

# # Namespace
# resource "kubernetes_namespace" "namespace" {
#   for_each = toset(var.namespaces)

#   metadata {
#     name = each.key
#   }
# }

# ## External Name
# resource "kubernetes_service" "externalname" {
#   depends_on = [kubernetes_namespace.namespace]
  
#   metadata {
#     name      = "mysql"
#     namespace = "infra"
#   }
#   spec {
#     type = "ExternalName"
#     external_name = var.db_instance_address
#   }
# }