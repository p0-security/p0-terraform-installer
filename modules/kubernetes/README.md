# Example: Terraform-Based Installation of K8s Integration

This folder contains example terraform code that will integrate P0 with a given EKS cluster; 
it does this by using the P0 terraform providers (p0_kubernetes_staged and p0_kubernetes) to
create and verify the installed integration; it also creates kubernetes resources (service accounts,
proxy deployments, etc) that are necessary for the integration to function.

In order to run `plan/apply/destroy` commands, the following environment variables need to be set
- P0_API_TOKEN (the value should be an API key generated in the web UI)
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_SESSION_TOKEN 

