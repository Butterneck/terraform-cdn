terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.15"
      configuration_aliases = [aws.general, aws.us-east-1]
    }
  }
}

data "aws_route53_zone" "selected" {
  zone_id = var.hosted_zone_id
}

locals {
  # Origin bucket name
  cdn_origin_bucket_name = "cdn-origin"

  # List of full subdomains (with domain appended)
  full_subdomains_list = [for subdomain in var.subdomains : "${subdomain}.${data.aws_route53_zone.selected.name}"]

  # Common tags applied to resources
  common_tags = {
    stack       = var.stack_name
    environment = var.environment
  }
}


### Logs Bucket ###

module "s3_cdn_origin_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.2"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  bucket = "${local.cdn_origin_bucket_name}-logs-${var.environment}"

  create_bucket = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_logs_write.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "s3_logs_write" {
  statement {
    sid = "S3 access log write"

    principals {
      type = "Service"
      identifiers = [
        "logging.s3.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${module.s3_cdn_origin_logs_bucket.s3_bucket_arn}/*"
    ]
  }
}

### Origin Bucket ###

module "s3_cdn_origin" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.2"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  bucket = "${local.cdn_origin_bucket_name}-${var.environment}"

  create_bucket = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.cloudfront_read.json

  logging = {
    target_bucket = module.s3_cdn_origin_logs_bucket.s3_bucket_id
    target_prefix = "log/"
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "cloudfront_read" {

  statement {
    sid = "CloudFront read access"

    principals {
      type = "AWS"
      identifiers = [
        module.cdn.cloudfront_origin_access_identity_iam_arns[0]
      ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${module.s3_cdn_origin.s3_bucket_arn}/*"
    ]
  }
}

### CDN ###

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 2.9"

  aliases = local.full_subdomains_list

  comment             = "My awesome CloudFront distribution"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_cdn_origin = "My awesome CloudFront distribution can access"
  }

  origin = {
    s3_cdn_origin = {
      domain_name = module.s3_cdn_origin.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_cdn_origin"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_cdn_origin"
    viewer_protocol_policy = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  tags = local.common_tags
}

### TLS Certificate ###

module "acm" {

  providers = {
    aws = aws.us-east-1
  }

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.5"

  domain_name = data.aws_route53_zone.selected.name
  zone_id     = var.hosted_zone_id

  subject_alternative_names = local.full_subdomains_list

  wait_for_validation = true

  tags = local.common_tags
}

### DNS Records ###

module "dns_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0.0"

  # Consciously put foreach there instead of on records field (even if chosen module is smart enough)
  for_each = var.subdomains

  zone_id = var.hosted_zone_id

  records = [
    {
      name = each.value
      type = "A"
      alias = {
        name    = module.cdn.cloudfront_distribution_domain_name
        zone_id = module.cdn.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}
