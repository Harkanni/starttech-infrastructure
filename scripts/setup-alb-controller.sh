#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# setup-alb-controller.sh
# Installs the AWS Load Balancer Controller into the EKS cluster. Without
# this, the Ingress resource in starttech-application/k8s/ingress.yaml has
# nothing watching it, and no ALB will ever be created.
#
# Auth model: no OIDC/IRSA. The controller pod inherits its AWS permissions
# from the EKS NODE GROUP's own IAM role (the EC2 instance profile), which
# is why step 2 attaches the controller's policy directly to that existing
# role rather than creating a separate federated identity.
#
# Order of operations:
#   1. Download AWS's official IAM policy for the controller (fetched
#      fresh from AWS's source, not hand-copied, since it's long and
#      security-sensitive).
#   2. terraform apply — attaches that policy to the node group role
#      (see modules/eks/alb-controller-policy.tf).
#   3. Helm-install the controller itself onto the cluster.
#
# Required env vars: EKS_CLUSTER_NAME, AWS_REGION, VPC_ID
#   (VPC_ID = terraform output vpc_id)
# ---------------------------------------------------------------------------

: "${EKS_CLUSTER_NAME:?Set EKS_CLUSTER_NAME}"
: "${AWS_REGION:?Set AWS_REGION}"
: "${VPC_ID:?Set VPC_ID (terraform output vpc_id)}"

cd "$(dirname "$0")/.."

echo "==> 1/4 downloading official AWS Load Balancer Controller IAM policy"
mkdir -p iam
curl -sSL -o iam/alb-controller-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

echo "==> 2/4 terraform apply (attaches policy to the EKS node group role)"
(cd terraform && terraform apply -auto-approve)

echo "==> 3/4 updating kubeconfig"
aws eks update-kubeconfig --name "${EKS_CLUSTER_NAME}" --region "${AWS_REGION}"

echo "==> 4/4 helm install aws-load-balancer-controller"
helm repo add eks https://aws.github.io/eks-charts >/dev/null
helm repo update >/dev/null
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="${EKS_CLUSTER_NAME}" \
  --set region="${AWS_REGION}" \
  --set vpcId="${VPC_ID}" \
  --set serviceAccount.create=true

echo ""
echo "Waiting for controller pods to become ready..."
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=120s

echo "ALB Controller installed. You can now apply k8s/ingress.yaml and it will provision a real ALB."