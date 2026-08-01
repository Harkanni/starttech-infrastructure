# ---------------------------------------------------------------------------
# AWS Load Balancer Controller permissions — attached directly to the
# existing EKS NODE GROUP role (not a separate per-pod identity). Pods
# running on these nodes inherit permissions from the node's own EC2
# instance profile, so the controller pod gets these permissions simply
# by running on the cluster — no OIDC/IRSA needed.
#
# Trade-off, stated plainly: every pod on these nodes technically has
# ALB-management permissions, not just the controller. Acceptable here
# since this is a single-tenant assessment cluster, not a shared one.
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "alb_controller" {
  name   = "starttech-alb-controller-policy"
  policy = file("${path.module}/../../../iam/alb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
