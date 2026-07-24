# ---------------------------------------------------------------------------
# Subnet Group: tells ElastiCache which subnets it's allowed to place its
# node in. We use the private subnets — same tier as the EKS workers that
# talk to it, never the public ones.
# ---------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "starttech" {
  name       = "starttech-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# ---------------------------------------------------------------------------
# Security Group: this is the actual firewall rule enforcing "only EKS
# workers can reach Redis." Ingress on port 6379 (Redis's default port) is
# scoped to traffic coming FROM the EKS cluster security group only — not
# from a CIDR block, not from the internet, not from anything else in the
# VPC. Anything not explicitly allowed is denied by default.
# ---------------------------------------------------------------------------
resource "aws_security_group" "redis" {
  name        = "starttech-redis-sg"
  description = "Allow Redis traffic only from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS workers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "starttech-redis-sg"
  }
}

# ---------------------------------------------------------------------------
# ElastiCache Redis: single-node cluster, cache.t3.micro, as specified.
# No replication/failover node since the spec calls for a single node —
# this is a caching layer, not the primary data store (that's MongoDB
# Atlas), so it's acceptable for it to be less durable.
# ---------------------------------------------------------------------------
resource "aws_elasticache_cluster" "starttech" {
  cluster_id           = "starttech-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.starttech.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name = "starttech-redis"
  }
}
