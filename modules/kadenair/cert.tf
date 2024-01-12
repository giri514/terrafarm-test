# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
 }

resource "aws_acm_certificate" "ssl_certificate" {
  domain_name       = var.certificatedomain
  subject_alternative_names = ["www.${var.certificatedomain}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
