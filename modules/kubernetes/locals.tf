locals {
  # Note this prevents a circular dependency between the PVC and the braekhus deployment
  p0_pvc_name = "p0-files-volume-claim"

  # Storage class name based on auto mode configuration
  # This prevents implicit dependencies on conditional resources
  storage_class_name = var.kubernetes.cluster.auto_mode_enabled ? "auto-ebs-sc" : "gp2"
}