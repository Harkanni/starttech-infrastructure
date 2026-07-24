output "cloudfront_domain_name" {
  description = "Public CloudFront domain — this is the single URL users and the frontend both use"
  value       = aws_cloudfront_distribution.starttech.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (useful for cache invalidations in CI/CD)"
  value       = aws_cloudfront_distribution.starttech.id
}
