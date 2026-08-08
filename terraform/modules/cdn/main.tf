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
  # Uses AWS's managed "CachingOptimized" policy — the modern replacement
  # for forwarded_values, and AWS's recommended approach going forward.
  default_cache_behavior {
    allowed_methods         = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = "S3-Frontend"
    viewer_protocol_policy  = "redirect-to-https"
    compress                = true
    cache_policy_id         = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
  }

  # Backend behaviors: routed by the REAL top-level prefixes the Go app
  # actually serves (confirmed from internal/routes) — there is no /api
  # prefix anywhere in this backend. The original devs deliberately picked
  # these names (e.g. /tasks instead of /todos) specifically to avoid
  # colliding with the frontend's React Router page routes, which is what
  # makes this split safe: any path NOT in this list falls through to the
  # default behavior (S3 + SPA fallback) below.
  ordered_cache_behavior {
    path_pattern              = "/health"
    allowed_methods           = ["GET", "HEAD"]
    cached_methods            = ["GET", "HEAD"]
    target_origin_id          = "ALB-Backend"
    viewer_protocol_policy    = "redirect-to-https"
    cache_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    origin_request_policy_id  = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # Managed-AllViewerExceptHostHeader
  }

  ordered_cache_behavior {
    path_pattern              = "/auth/*"
    allowed_methods           = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods            = ["GET", "HEAD"]
    target_origin_id          = "ALB-Backend"
    viewer_protocol_policy    = "redirect-to-https"
    cache_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id  = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern              = "/tasks*"
    allowed_methods           = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods            = ["GET", "HEAD"]
    target_origin_id          = "ALB-Backend"
    viewer_protocol_policy    = "redirect-to-https"
    cache_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id  = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern              = "/users/*"
    allowed_methods           = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods            = ["GET", "HEAD"]
    target_origin_id          = "ALB-Backend"
    viewer_protocol_policy    = "redirect-to-https"
    cache_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id  = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern              = "/swagger/*"
    allowed_methods           = ["GET", "HEAD"]
    cached_methods            = ["GET", "HEAD"]
    target_origin_id          = "ALB-Backend"
    viewer_protocol_policy    = "redirect-to-https"
    cache_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id  = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
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
