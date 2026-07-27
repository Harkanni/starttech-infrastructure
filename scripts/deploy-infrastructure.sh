#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# deploy-infrastructure.sh
#
# Runs the two-phase Terraform apply this architecture requires:
#   Phase 1 — everything EXCEPT the CDN module (CDN needs a real ALB DNS
#             name, which doesn't exist until Kubernetes creates one).
#   [ manual step: deploy k8s manifests from starttech-application,
#     which creates the ALB via the Ingress ]
#   Phase 2 — full apply, now the `data "aws_lb"` lookup resolves and the
#             CDN module can actually build.
#
# Run this script twice: once before k8s manifests are applied, once after.
# ---------------------------------------------------------------------------

cd "$(dirname "$0")/../terraform"

echo "==> terraform fmt -check"
terraform fmt -check -recursive

echo "==> terraform init"
terraform init -upgrade

echo "==> terraform validate"
terraform validate

if [ "${1:-}" == "--phase2" ]; then
  echo "==> PHASE 2: full apply (requires ALB to already exist — see ingress.yaml)"
  terraform plan -out=tfplan
  terraform apply tfplan
else
  echo "==> PHASE 1: applying everything except the CDN module"
  echo "    (run this script again with --phase2 AFTER deploying k8s manifests)"
  terraform plan \
    -target=module.networking \
    -target=module.eks \
    -target=module.storage \
    -target=module.database \
    -out=tfplan
  terraform apply tfplan
  echo ""
  echo "Phase 1 complete. Next steps:"
  echo "  1. In starttech-application: ./scripts/deploy-backend.sh"
  echo "     (this creates the ALB via the k8s Ingress)"
  echo "  2. Come back here and run: ./scripts/deploy-infrastructure.sh --phase2"
fi