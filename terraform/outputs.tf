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
