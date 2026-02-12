terraform {
  required_providers {
    p0 = {
      source = "p0-security/p0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Sets up authentication with the cluster; This expects AWS CLI authentication is available in
# the shell running terraform. You should be able to run "aws eks update-kubeconfig ..."
# against the cluster you're currently installing the P0 integration on.
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.kubernetes.cluster.id,
      "--region",
      var.kubernetes.cluster.region
    ]
  }
}