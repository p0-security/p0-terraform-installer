locals {
  # Note this prevents a circular dependency between the PVC and the braekhus deployment
  p0_pvc_name = "p0-files-volume-claim"
}