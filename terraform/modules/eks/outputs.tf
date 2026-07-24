output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.starttech.name
}

output "cluster_endpoint" {
  description = "API server endpoint for the EKS cluster"
  value       = aws_eks_cluster.starttech.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for cluster auth"
  value       = aws_eks_cluster.starttech.certificate_authority[0].data
}

output "node_group_role_arn" {
  description = "IAM role ARN used by worker nodes (referenced by other resources needing node-level trust)"
  value       = aws_iam_role.eks_node_group.arn
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID — used to restrict access to resources like ElastiCache to EKS workers only"
  value       = aws_eks_cluster.starttech.vpc_config[0].cluster_security_group_id
}