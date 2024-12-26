# modules/acm/variables.tf

variable "domain_name" {
  description = "A domain name for which the certificate should be issued"
  type = string
}

variable "zone_id" {
  description = "The ID of the hosted zone to contain this record. Required when validating via Route53"
  type = string
}

variable "validation_method" {
  description = "Which method to use for validation. DNS or EMAIL are valid"
  type = string
}

variable "subject_alternative_names" {
  description = "A list of domains that should be SANs in the issued certificate"
  type = list(string)
}