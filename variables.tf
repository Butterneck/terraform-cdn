variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Valid values for `cloudfront_price_class` are ('PriceClass_100', 'PriceClass_200', 'PriceClass_All')"
  }
}

variable "stack_name" {
  description = "Stack name"
  type        = string

  validation {
    condition     = can(regex("Stack$", var.stack_name))
    error_message = "Stack name must match against 'Stack$' regex"
  }
}

variable "environment" {
  description = "Environment stage"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "quality", "production"], var.environment)
    error_message = "Valid values for `environment` are ('development', 'quality', 'production')"
  }
}

variable "hosted_zone_id" {
  description = "ID of the Hosted Zone where domains are registered"
  type        = string
}

variable "subdomains" {
  description = "Subdomains"
  type        = set(string)

  validation {
    condition     = length(var.subdomains) == 5
    error_message = "You must provide 5 subdomains"
  }
}