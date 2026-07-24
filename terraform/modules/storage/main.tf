# ---------------------------------------------------------------------------
# S3 Bucket: Frontend static assets
# Kept fully private — CloudFront (via Origin Access Control) is the only
# thing permitted to read from it. No public bucket policy, no website
# hosting config on the bucket itself.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name

  tags = {
    Name = "starttech-frontend-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning is a safety net: if a bad frontend build gets deployed, we can
# roll back to the previous object version without redeploying from scratch.
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# ECR Repository: Backend Docker images
# Scanned on push so vulnerabilities in the base image / dependencies are
# caught before EKS ever pulls the image.
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "backend" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "starttech-backend-api"
  }
}
