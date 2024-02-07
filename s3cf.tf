provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "static_website" {
  bucket = "s3class51971"
}

resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false 
  restrict_public_buckets = false 
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.static_website.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
  depends_on = [
    aws_s3_bucket.static_website,
    aws_s3_bucket_public_access_block.static_website
  ]
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::s3class51971/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  version = "2012-10-17"
}

# Upload the files into the bucket
resource "aws_s3_bucket_object" "s3class1971" {
  bucket       = aws_s3_bucket.static_website.id
  for_each     = {
    "audio.mp3"           = "audio/mpeg",
    "index.html"          = "text/html",
    "slide.css"           = "text/css",
    "slide.js"            = "text/javascript",
    "LW2_Guyanese1.jpg"   = "image/jpeg",
    "LW2_Guyanese4.jpg"   = "image/jpeg",
    "LW2_Guyanese6.jpg"   = "image/jpeg"
  }
  key          = each.key
  source       = "./${each.key}"
  content_type = each.value
  etag         = filemd5("./${each.key}")
}

# Create an OAI for the S3 bucket and CloudFront distribution
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for restricting access to S3 bucket"

  # Add any other desired configurations for the OAI
}

# Update the S3 bucket policy to allow access from the OAI
resource "aws_s3_bucket_policy" "s3_bucket_oai_policy" {
  bucket = aws_s3_bucket.static_website.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

# Update the CloudFront distribution to use the OAI as the Origin Access Identity
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_website.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id         = "S3-${aws_s3_bucket.static_website.id}"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy   = "redirect-to-https"
    min_ttl                  = 0
    default_ttl              = 3600
    max_ttl                  = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "CloudFront Distribution"
  }
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

