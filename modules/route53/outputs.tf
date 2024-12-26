# # modules/route53/outputs.tf

output "route53_zone_zone_id" {
  description = "Zone ID of Route53 zone"
  value       = module.zones.route53_zone_zone_id["outstagram.shop"]
}