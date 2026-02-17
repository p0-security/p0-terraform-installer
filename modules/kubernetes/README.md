# Example: Terraform-Based Installation of K8s Integration

## Overview
This folder contains example terraform code that will integrate P0 with a given EKS cluster; 
it does this by using the P0 terraform providers (p0_eks_kubernetes_staged and p0_eks_kubernetes) to
create and verify the installed integration; it also creates kubernetes resources (service accounts,
proxy deployments, etc) that are necessary for the integration to function.

## EKS Auto-Mode
This terraform code will provision a modified set of resources depending on whether or not the EKS cluster
being targeted is configured to use EKS Auto-Mode. The user is currently required to specify whether or not
this is the case for each cluster.

## Instructions
1. Run `cd kubernetes` to change your working directory to this folder.
2. Run `terraform init` to initialize terraform and retrieve provider dependencies.
3. Create your own `terraform.tfvars` file, containing information on the EKS cluster you wish to install the P0 integration on. See `kubernetes/terraform.tfvars.example` for what this file should look like.
4. Export required environment variables:
    - `P0_API_TOKEN`
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
    - `AWS_SESSION_TOKEN`
5. Run `aws eks update-kubeconfig --name <cluster name> --region <cluster region>`
6. Run `terraform plan` to view the resources that will be provisioned by this module.
7. Run `terraform apply` to provision the resources. Once complete, you should see an installed K8s integration appear in the P0 web app, under "Integrations", and you should be able to request access.
