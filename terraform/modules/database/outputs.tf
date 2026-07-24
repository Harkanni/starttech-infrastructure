output "redis_endpoint" {
  description = "Redis primary endpoint address — this is what the Go backend sets as REDIS_HOST"
  value       = aws_elasticache_cluster.starttech.cache_nodes[0].address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_cluster.starttech.port
}
