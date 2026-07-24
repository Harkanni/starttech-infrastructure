# ---------------------------------------------------------------------------
# Origin Access Control: lets CloudFront authenticate directly to the
# private S3 bucket. Replaces the older "Origin Access Identity" pattern.
# ---------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "starttech-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------------------------------------------------------------------
# CloudFront Distribution: single distribution, two origins, acting as a
# unified reverse proxy so the browser only ever sees one HTTPS domain.
# ---------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "starttech" {
  enabled             = true
  default_root_object = "index.html"

  # Origin 1: S3 (React static assets), authenticated via OAC
  origin {
    domain_name              = var.frontend_bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Origin 2: ALB (Go backend API), plain HTTP — CloudFront terminates
  # HTTPS on the front, connects to the ALB over HTTP behind the scenes.
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-Backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior (*): serve the React app from S3, force HTTPS
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress                = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # /api/* behavior: route dynamic traffic to the ALB, caching fully
  # disabled, everything forwarded so the Go backend can parse cookies,
  # CORS headers, and query strings itself.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-Backend"
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  # SPA routing fix: rewrite 403/404 from S3 into a 200 for /index.html so
  # client-side routes (e.g. /dashboard) survive a browser refresh.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
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
    Name = "starttech-cdn"
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket Policy: grants read access ONLY to this specific CloudFront
# distribution (via OAC), not to the public or any other AWS account.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "frontend_oac" {
  bucket = var.frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${var.frontend_bucket_arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.starttech.arn
        }
      }
    }]
  })
}
