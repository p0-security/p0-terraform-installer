# Data source for EKS cluster information
data "aws_eks_cluster" "cluster" {
  name = var.kubernetes.cluster.id
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {
}

# Data source to get the TLS certificate for the OIDC provider thumbprint
data "tls_certificate" "cluster" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}