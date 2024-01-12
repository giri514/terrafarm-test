
data "aws_cloudfront_response_headers_policy" "Managed-CORS-and-SecurityHeadersPolicy" {
  name = "Managed-CORS-and-SecurityHeadersPolicy"
}

locals {
  has_waf = var.WAF == "true"
}

resource "aws_cloudfront_distribution" "reece_cloudfront_distribution" {

  web_acl_id          = local.has_waf ? "f7e56dd1-986c-452e-a973-4ae89469b7da" : null
  aliases             = [var.DomainName, "www.${var.DomainName}"]
  default_root_object = "index.html"
  comment             = var.DomainNameDashes
  enabled             = true
  http_version        = "http2"
  price_class         = "PriceClass_All"
  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate.ssl_certificate.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true
    target_origin_id = "s3-bucket"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.Managed-CORS-and-SecurityHeadersPolicy.id

  }

  ordered_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-bucket"
    path_pattern     = "/*"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.Managed-CORS-and-SecurityHeadersPolicy.id
  }

  origin {
    domain_name = "${aws_s3_bucket.reece_s3_bucket.id}.s3-website.us-east-1.amazonaws.com"
    origin_id   = "s3-bucket"
    custom_origin_config {
      origin_ssl_protocols   = ["TLSv1.2"]
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
    }
  }

  logging_config {
    bucket          = "${aws_s3_bucket.log_bucket.id}.s3.amazonaws.com"
    prefix          = var.DomainNameDashes
    include_cookies = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "MX", "IN"]
    }
  }

  depends_on = [aws_s3_bucket.reece_s3_bucket]
}

resource "aws_cloudfront_origin_access_identity" "reece_cloudfront_origin_access_identity" {
  comment = "CF for ${var.DomainName}"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.DomainNameDashes}-logs"

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 1
    }
    expiration {
      days = var.LogRetention
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket" {
  depends_on = [
    aws_s3_bucket_public_access_block.log_bucket,
    aws_s3_bucket_ownership_controls.log_bucket,
  ]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "reece_s3_bucket_policy" {
  bucket = aws_s3_bucket.reece_s3_bucket.id

  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Id": "GetObjectFromS3",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.reece_s3_bucket.id}/*"
        }
    ]
}
EOF
  depends_on = [aws_s3_bucket.reece_s3_bucket]

}

resource "aws_s3_bucket" "reece_s3_bucket" {
  bucket = var.DomainNameDashes

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = {
    Domain = var.DomainName
  }
}

resource "aws_s3_bucket_public_access_block" "reece_s3_bucket" {
  bucket = aws_s3_bucket.reece_s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "reece_s3_bucket" {
  bucket = aws_s3_bucket.reece_s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "reece_s3_bucket" {
  depends_on = [
    aws_s3_bucket_public_access_block.reece_s3_bucket,
    aws_s3_bucket_ownership_controls.reece_s3_bucket,
  ]

  bucket = aws_s3_bucket.reece_s3_bucket.id
  acl    = "public-read"
}

