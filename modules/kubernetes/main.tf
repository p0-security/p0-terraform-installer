# Initializes configuration for the integration and generates PKI values for later use
resource "p0_kubernetes_staged" "tf-staged-test-cluster" {
  id                    = var.kubernetes.cluster.id
  connectivity_type     = "proxy"
  hosting_type          = "aws"
  cluster_arn           = var.kubernetes.cluster.arn
  cluster_endpoint      = var.kubernetes.cluster.endpoint
  certificate_authority = var.kubernetes.cluster.cert_authority
}

resource "kubernetes_namespace_v1" "p0_security" {
  metadata {
    name = "p0-security"
  }
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.kubernetes.cluster.auto_mode_enabled ? 0 : 1
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
}

resource "kubernetes_storage_class_v1" "auto_ebs" {
  count = var.kubernetes.cluster.auto_mode_enabled ? 1 : 0

  metadata {
    name = "auto-ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.eks.amazonaws.com"
  volume_binding_mode = "Immediate"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  count = var.kubernetes.cluster.auto_mode_enabled ? 0 : 1

  name = "AmazonEKS_EBS_CSI_DriverRole_${var.kubernetes.cluster.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = var.kubernetes.cluster.auto_mode_enabled ? 0 : 1

  role       = aws_iam_role.ebs_csi_driver[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.kubernetes.cluster.auto_mode_enabled ? 0 : 1

  cluster_name             = var.kubernetes.cluster.id
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver[0].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}

resource "kubernetes_persistent_volume_claim_v1" "p0_files_volume_claim" {
  metadata {
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
    name      = local.p0_pvc_name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = local.storage_class_name

    resources {
      requests = {
        storage = "10Mi"
      }
    }
  }
}

# Creates the P0 Braekhus proxy
resource "kubernetes_deployment_v1" "p0_braekhus_proxy" {
  metadata {
    name      = "p0-braekhus-proxy"
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "p0-braekhus-proxy"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        name = "p0-braekhus-proxy"
        labels = {
          "app.kubernetes.io/name" = "p0-braekhus-proxy"
        }
      }

      spec {
        init_container {
          name  = "p0-certs-setup"
          image = "bash"
          args = [
            "-c",
            "echo ${var.kubernetes.cluster.cert_authority} | base64 -d | tee /p0-files/ca.pem"
          ]

          volume_mount {
            mount_path = "/p0-files"
            name       = "p0-files-storage"
          }
        }

        container {
          name              = "braekhus"
          image             = "p0security/braekhus:latest"
          image_pull_policy = "Always"

          args = [
            "start:prod:client",
            "--targetUrl",
            var.kubernetes.cluster.endpoint,
            "--clientId",
            "p0-gus:${var.kubernetes.cluster.id}",
            "--jwkPath",
            "/p0-files",
            "--tunnelHost",
            "${var.p0_config.org}.braekhus.p0.app",
            "--tunnelPort",
            "443"
          ]

          env {
            name  = "NODE_EXTRA_CA_CERTS"
            value = "/p0-files/ca.pem"
          }

          resources {
            limits = {
              memory = "2Gi"
              cpu    = "1"
            }
            requests = {
              memory = "1Gi"
              cpu    = "1"
            }
          }

          volume_mount {
            mount_path = "/p0-files"
            name       = "p0-files-storage"
          }
        }

        volume {
          name = "p0-files-storage"

          persistent_volume_claim {
            claim_name = local.p0_pvc_name
            read_only  = false
          }
        }
      }
    }
  }

  depends_on = [p0_kubernetes_staged.tf-staged-test-cluster]
}

resource "kubernetes_service_account_v1" "p0_service_account" {
  metadata {
    name      = "p0-service-account"
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
  }

  depends_on = [p0_kubernetes_staged.tf-staged-test-cluster]
}

resource "kubernetes_secret_v1" "p0_service_account_secret" {
  metadata {
    name      = "p0-service-account-secret"
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.p0_service_account.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true

}

resource "kubernetes_cluster_role_v1" "p0_service_role" {
  metadata {
    name = "p0-service-role"
  }

  rule {
    api_groups = [""]
    resources  = ["bindings", "configmaps", "endpoints", "events", "limitranges", "namespaces", "namespaces/status", "nodes", "persistentvolumeclaims", "persistentvolumeclaims/status", "pods", "pods/log", "pods/status", "replicationcontrollers", "replicationcontrollers/scale", "replicationcontrollers/status", "resourcequotas", "resourcequotas/status", "serviceaccounts", "services", "services/status"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["controllerrevisions", "daemonsets", "daemonsets/status", "deployments", "deployments/scale", "deployments/status", "replicasets", "replicasets/scale", "replicasets/status", "statefulsets", "statefulsets/scale", "statefulsets/status"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers", "horizontalpodautoscalers/status"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "cronjobs/status", "jobs", "jobs/status"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets", "daemonsets/status", "deployments", "deployments/scale", "deployments/status", "ingresses", "ingresses/status", "networkpolicies", "replicasets", "replicasets/scale", "replicasets/status", "replicationcontrollers/scale"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets", "poddisruptionbudgets/status"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "ingresses/status", "networkpolicies"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["list"]
  }

  rule {
    api_groups     = [""]
    resource_names = ["aws-auth"]
    resources      = ["configmaps"]
    verbs          = ["get", "create", "patch", "update"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "clusterroles"]
    verbs      = ["get", "list", "create", "patch", "update", "delete", "bind", "escalate"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings", "clusterrolebindings"]
    verbs      = ["get", "list", "create", "patch", "update", "delete"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "p0_service_role_binding" {
  metadata {
    name = "p0-service-role-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.p0_service_account.metadata[0].name
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.p0_service_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Creates the P0 admission-controller
resource "kubernetes_deployment_v1" "p0_admission_controller" {
  metadata {
    name      = "p0-admission-controller"
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "p0-admission-controller"
      }
    }

    template {
      metadata {
        name = "p0-admission-controller"
        labels = {
          "app.kubernetes.io/name" = "p0-admission-controller"
        }
      }

      spec {
        container {
          name              = "webhook"
          image             = "p0security/p0-k8s-admission-controller:latest"
          image_pull_policy = "Always"

          args = [
            "/webhook",
            "--tls-cert",
            p0_kubernetes_staged.tf-staged-test-cluster.server_cert,
            "--tls-private-key",
            p0_kubernetes_staged.tf-staged-test-cluster.server_key,
            "--port",
            "8080"
          ]

          resources {
            limits = {
              memory = "50Mi"
              cpu    = "300m"
            }
            requests = {
              memory = "50Mi"
              cpu    = "300m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "p0_admission_controller" {
  metadata {
    name      = "p0-admission-controller"
    namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
    labels = {
      name = "p0-admission-controller"
    }
  }

  spec {
    port {
      name        = "webhook"
      port        = 443
      target_port = 8080
    }

    selector = {
      "app.kubernetes.io/name" = "p0-admission-controller"
    }
  }
}

resource "kubernetes_validating_webhook_configuration_v1" "p0_admission_controller" {
  metadata {
    name = "p0-admission-controller"
  }

  webhook {
    name = "p0-admission-controller.p0-security.svc"

    rule {
      api_groups   = ["rbac.authorization.k8s.io"]
      api_versions = ["v1"]
      operations   = ["CREATE", "UPDATE"]
      resources    = ["clusterroles", "clusterrolebindings", "rolebindings"]
    }

    client_config {
      service {
        namespace = kubernetes_namespace_v1.p0_security.metadata[0].name
        name      = kubernetes_service_v1.p0_admission_controller.metadata[0].name
        path      = "/validate"
      }

      ca_bundle = p0_kubernetes_staged.tf-staged-test-cluster.ca_bundle
    }

    admission_review_versions = ["v1beta1", "v1"]
    side_effects              = "None"
    failure_policy            = "Fail"
    timeout_seconds           = 5
  }
}

data "external" "braekhus_public_jwk" {
  program = ["bash", "-c", "kubectl exec deploy/p0-braekhus-proxy -n p0-security -c braekhus -- cat /p0-files/jwk.public.json | jq -c | jq -Rs '{public_jwk: .}'"]

  depends_on = [kubernetes_deployment_v1.p0_braekhus_proxy]
}

# Adds access credentials to the intergration configuration and verifies installation
resource "p0_kubernetes" "tf-test-cluster" {
  id         = var.kubernetes.cluster.id
  token      = kubernetes_secret_v1.p0_service_account_secret.data["token"]
  public_jwk = data.external.braekhus_public_jwk.result.public_jwk

  connectivity_type     = "proxy"
  hosting_type          = "aws"
  cluster_arn           = var.kubernetes.cluster.arn
  cluster_endpoint      = var.kubernetes.cluster.endpoint
  certificate_authority = var.kubernetes.cluster.cert_authority

  depends_on = [data.external.braekhus_public_jwk]
}