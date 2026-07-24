terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }

  backend "s3" {
    bucket       = "starttech-terraform-state-file-bucket-cloud-provider"
    key          = "state/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }

}

provider "aws" {
  region = var.aws_region
}



module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  cluster_name         = var.cluster_name
  project_name         = var.project_name
}

# ---------------------------------------------------------------------------
# 2. EKS — the cluster and node group, placed in the private subnets
# ---------------------------------------------------------------------------
module "eks" {
  source             = "./modules/eks"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
}

# ---------------------------------------------------------------------------
# 3. Storage — S3 frontend bucket + ECR repo (independent of networking)
# ---------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"
}

# ---------------------------------------------------------------------------
# 4. Database — Redis, locked down to EKS workers only
# ---------------------------------------------------------------------------
module "database" {
  source                         = "./modules/database"
  vpc_id                         = module.networking.vpc_id
  private_subnet_ids             = module.networking.private_subnet_ids
  eks_cluster_security_group_id  = module.eks.cluster_security_group_id
}

# ---------------------------------------------------------------------------
# ALB lookup — this is the two-phase-apply seam. On a FIRST apply (before
# the k8s Ingress has run), this data source will fail to find a match.
# That's expected: apply everything else first, deploy k8s manifests
# (which creates the ALB via alb.ingress.kubernetes.io/load-balancer-name),
# then re-run apply so this resolves and the CDN module can build.
# ---------------------------------------------------------------------------
data "aws_lb" "backend" {
  name = var.alb_load_balancer_name
}

# ---------------------------------------------------------------------------
# 5. CDN — single CloudFront distribution, S3 + ALB origins
#    Depends on the ALB already existing (see note above).
# ---------------------------------------------------------------------------
module "cdn" {
  source                                 = "./modules/cdn"
  frontend_bucket_regional_domain_name   = module.storage.frontend_bucket_regional_domain_name
  frontend_bucket_arn                    = module.storage.frontend_bucket_arn
  frontend_bucket_id                     = module.storage.frontend_bucket_id
  alb_dns_name                           = data.aws_lb.backend.dns_name
}

