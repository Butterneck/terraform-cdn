# CDN Module

Terraform module which creates a content delivery network (CDN) from a S3 bucket and distribute it via Cloudfront on AWS.

## Usage

```hcl
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}


module "my_cdn" {
    source = "github.com/butterneck/terraform-cdn.git"

    providers = {
        aws.general = aws
        aws.us-east-1 = aws.us-east-1
    }

    stack_name = "FooStack"
    cloudfront_price_class = "PriceClass_100"
    environment = "development"
    hosted_zone_id = "Z08752114L2492F7S4Y03"
    subdomains = [
        "sub1",
        "sub2",
        "sub3",
        "sub4",
        "sub5",
    ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.15 |

## Providers

All module's resources will be created using the `aws.general` provider, except for the ACM Certificate used by CloudFront, because it expects ACM resources in `us-east-1` region only. 

In order to deploy all other resources on your preferred region you also need to provide the module with an alias provider (`aws.us-east-1`) which uses the `us-east-1` region which will be used to deploy the ACM Certificate on the correct region.
 
| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.15 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 3.5 |
| <a name="module_cdn"></a> [cdn](#module\_cdn) | terraform-aws-modules/cloudfront/aws | ~> 2.9 |
| <a name="module_dns_records"></a> [dns\_records](#module\_dns\_records) | terraform-aws-modules/route53/aws//modules/records | ~> 2.0.0 |
| <a name="module_s3_bucket_logs"></a> [s3\_bucket\_logs](#module\_s3\_bucket\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 3.2 |
| <a name="module_s3_cdn_origin"></a> [s3\_cdn\_origin](#module\_s3\_cdn\_origin) | terraform-aws-modules/s3-bucket/aws | ~> 3.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.cloudfront_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_logs_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | CloudFront price class | `string` | `"PriceClass_100"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment stage | `string` | `"development"` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | ID of the Hosted Zone where domains are registered | `string` | n/a | yes |
| <a name="input_stack_name"></a> [stack\_name](#input\_stack\_name) | Stack name | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | Subdomains | `set(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cdn_domain_names"></a> [cdn\_domain\_names](#output\_cdn\_domain\_names) | Domain which points to the CDN |
| <a name="output_cdn_origin_bucket_id"></a> [cdn\_origin\_bucket\_id](#output\_cdn\_origin\_bucket\_id) | Name of the cdn-origin bucket |
| <a name="output_cdn_origin_logs_bucket_id"></a> [cdn\_origin\_logs\_bucket\_id](#output\_cdn\_origin\_logs\_bucket\_id) | Name of the cdn-origin logs bucket |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | Domain of the CloudFront distribution |

# Authors
Module is maintained by [Filippo Pinton](https://github.com/Butterneck)

# License
Apache 2 Licensed. See [LICENSE](https://github.com/Butterneck/terraform-cdn/tree/main/LICENSE) for full details.