resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "index.html"
  source       = "index.html"  
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "styles_css" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "styles.css"
  source       = "styles.css"
  content_type = "text/css"
}

resource "aws_s3_bucket_public_access_block" "website_bucket_public_access" {
  bucket                 = aws_s3_bucket.website_bucket.id
  block_public_acls      = false
  block_public_policy    = false
  ignore_public_acls     = false
  restrict_public_buckets = false
}

resource "aws_cloudfront_origin_access_identity" "example" {
  comment = "Origin Access Identity for my static website"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = "${aws_s3_bucket.website_bucket.bucket}.s3.amazonaws.com"
    origin_id   = "S3-${aws_s3_bucket.website_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example.id
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.example.id}"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

