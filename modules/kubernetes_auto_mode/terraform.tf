terraform {
  required_providers {
    p0 = {
      source = "p0-security/p0"
      version = "~> 0.28.0"
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

provider "p0" {
  host = var.p0_config.host
  org  = var.p0_config.org
}

provider "aws" {
  region = var.kubernetes.cluster.region
}
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