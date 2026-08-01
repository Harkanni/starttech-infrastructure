output "root_vpc_id" {
  description = "The ID of the created VPC"
  value       = module.networking.vpc_id
}

output "root_public_subnets" {
  description = "The IDs of the created public subnets"
  value       = module.networking.public_subnet_ids
}

output "root_private_subnets" {
  description = "The IDs of the created private subnets"
  value       = module.networking.private_subnet_ids
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR repo URL — CI/CD pushes backend images here"
  value       = module.storage.ecr_repository_url
}

output "frontend_bucket_id" {
  description = "S3 frontend bucket name — CI/CD syncs built React assets here"
  value       = module.storage.frontend_bucket_id
}

output "redis_endpoint" {
  description = "Redis endpoint — set as REDIS_HOST in the backend deployment"
  value       = module.database.redis_endpoint
}

output "cloudfront_domain_name" {
  description = "Public CloudFront URL — the single domain serving both frontend and /api/*"
  value       = one(module.cdn[*].cloudfront_domain_name)
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — used for cache invalidation in the frontend CI/CD pipeline"
  value       = one(module.cdn[*].cloudfront_distribution_id)
}

