variable "frontend_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name from the storage module (S3 origin)"
  type        = string
}

variable "frontend_bucket_arn" {
  description = "S3 bucket ARN from the storage module (used in the bucket policy for OAC)"
  type        = string
}

variable "frontend_bucket_id" {
  description = "S3 bucket name/ID from the storage module"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the backend Application Load Balancer (ALB origin, plain HTTP)"
  type        = string
}
