# # modules/route53/variables.tf

variable "zone_names" {
  type = map(object({
    comment = string
    tags    = map(string)
  }))
  default = {
    "outstagram.shop" = {
      comment = "Dev environment for outstagram.shop"
      tags    = {
        service       = "outstagram"
        environment   = "dev"
      }
    }
  }
}
