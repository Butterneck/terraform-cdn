output "cloudfront_distribution_domain_name" {
  description = "Domain of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "cdn_origin_bucket_id" {
  description = "Name of the cdn-origin bucket"
  value       = module.s3_cdn_origin.s3_bucket_id
}

output "cdn_origin_logs_bucket_id" {
  description = "Name of the cdn-origin logs bucket"
  value       = module.s3_cdn_origin_logs_bucket.s3_bucket_id
}

output "cdn_domain_names" {
  description = "Domain which points to the CDN"
  value = [
    for record in module.dns_records : record.route53_record_fqdn
  ]
}