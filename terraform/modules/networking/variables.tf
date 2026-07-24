variable "project_name" {
  description = "The name of the PROJECT for resource tagging"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources"
  type        = list(string)
}

variable "cluster_name" {
  description = "The name of the EKS cluster for resource tagging"
  type        = string
}
