variable "frontend_bucket_name" {
  description = "S3 bucket name for the React frontend static assets"
  type        = string
  default     = "starttech-frontend-bucket-851438481377"
}

variable "ecr_repo_name" {
  description = "ECR repository name for the Go backend Docker images"
  type        = string
  default     = "starttech-backend-api"
}
