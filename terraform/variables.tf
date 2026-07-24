variable "project_name" {
  description = "The name of the PROJECT for resource tagging"
  type        = string
  default     = "starttech-vpc"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "cluster_name" {
  description = "The name of the EKS cluster for resource tagging"
  type        = string
  default     = "starttech-cluster"
}

variable "azs" {
  description = "Availability Zones to spread subnets across (must be 2, in aws_region)"
  type        = list(string)
}

variable "alb_load_balancer_name" {
  description = "Fixed name given to the ALB via the k8s Ingress annotation alb.ingress.kubernetes.io/load-balancer-name — lets Terraform look it up by name once k8s creates it"
  type        = string
  default     = "starttech-alb"
}