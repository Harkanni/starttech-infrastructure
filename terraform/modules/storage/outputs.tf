output "frontend_bucket_id" {
  description = "S3 bucket name/ID (used by the CDN module for the OAC origin)"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "S3 bucket ARN (used in the bucket policy granting CloudFront OAC read access)"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_regional_domain_name" {
  description = "Regional domain name (used as the CloudFront S3 origin domain)"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "ecr_repository_url" {
  description = "ECR repository URL (used by CI/CD to push backend images)"
  value       = aws_ecr_repository.backend.repository_url
}
