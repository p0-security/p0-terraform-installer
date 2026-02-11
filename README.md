## p0-terraform-install

Deploy P0 integrations into an existing Okta + AWS environment using Terraform.

This module set is intended to bootstrap everything P0 needs to:

- authenticate users via Okta
- discover Okta groups
- manage AWS IAM permission sets and policies
- inventory AWS resources
- enable SSH access to EC2 instances via AWS Systems Manager
- define sample routing rules for fine‑grained access control in P0

### Integrations provided

- **Okta login**
  - Creates a native Okta OIDC application used for sign-in to the P0 web app (e.g. https://p0.app) and the P0 CLI.
  - Uses PKCE and device / token‑exchange flows, with no client secret (`omit_secret = true`).

- **Okta group listing**
  - Creates custom Okta admin roles and resource sets to allow P0 to:
    - **read all users** (`okta.users.read`)
    - **read all groups** (`okta.groups.read`)
  - Creates a service OIDC app that P0 uses to list users and groups, and assigns:
    - appropriate OAuth scopes to the app
    - the custom “directory lister” admin role to that app, scoped to users and groups.

- **AWS IAM management**
  - Provisions IAM roles, policies, and related configuration needed for P0 to request and manage:
    - AWS SSO permission sets / roles
    - policy-based access to AWS resources
  - Integrates with an existing AWS IAM Identity Center (SSO) instance using the configured parent account ID.

- **AWS resource inventory**
  - Configures AWS Resource Explorer and supporting IAM policy so P0 can:
    - discover EC2, RDS, and other AWS resources across regions
    - use that inventory when users request access to specific resources.

- **AWS SSH**
  - Configures AWS Systems Manager (SSM) for SSH access to EC2 instances.
  - Deploys SSM documents used by P0 for:
    - provisioning SSH users and keys
    - retrieving SSH host keys.

- **Sample routing rules**
  - Provides example routing rules that show how P0 can:
    - map Okta groups, AWS attributes, and P0 metadata
    - enforce fine‑grained, just‑in‑time access patterns.

### Prerequisites

- **Terraform**
  - **Terraform CLI** `1.8.0` (this repo pins `required_version = "= 1.8.0"`).
  - Recommended: [`tfenv`](https://github.com/tfutils/tfenv) to manage Terraform versions.

- **AWS**
  - An AWS account with:
    - IAM Identity Center (SSO) configured (or the current account used as the Identity Center parent).
    - Permission to create and manage:
      - IAM roles, policies, and SSM documents
      - Resource Explorer indexes and views.
  - Credentials exported via standard environment variables:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
    - optional `AWS_SESSION_TOKEN` for temporary credentials.

- **Okta**
  - An Okta org with API access enabled.
  - An Okta **API service app** (Client Credentials flow, private key JWT) that **Terraform** uses to create and manage Okta resources. This is the app whose credentials you put in `terraform.tfvars` and `OKTA_API_PRIVATE_KEY`, and it is **distinct** from the Okta apps that this Terraform code will create for P0 itself (the P0 login native app and the P0 Okta integration service app):
    - Create the service app in the Okta Admin Console (e.g. **Applications → Create App Integration → API Services**). Add a public key and note the **client ID** and **private key ID**.
    - Store the PEM‑encoded private key (starting with `-----BEGIN PRIVATE KEY-----`) in the `OKTA_API_PRIVATE_KEY` environment variable. You can export a PEM from the Okta UI or use the repo’s `jwk-to-pem.py` script if your key is in JWK form.
    - In the Okta Admin Console, grant this app the following **OAuth 2.0 scopes** (required for the Terraform resources in this repo):
      - `okta.roles.manage` – create custom admin roles and resource sets, and assign roles to apps
      - `okta.roles.read` – read roles and resource sets
      - `okta.apps.manage` – create and manage OAuth apps (the P0 login app and the P0 API integration app) and their API scopes
      - `okta.apps.read` – read app information
    - The list of scopes in your Terraform provider config (`okta.tfauth.scopes` in `terraform.tfvars`) must include at least these four; it may list more (e.g. `terraform.tfvars.example` includes a broader set from earlier development). See [Okta OAuth 2.0 scopes](https://developer.okta.com/docs/api/oauth2/) and [Control Terraform access to Okta](https://developer.okta.com/docs/guides/terraform-design-access-security/main/).

- **P0**
  - A P0 organization configured in the P0 app.
  - A **P0 API token** created in the P0 UI:
    - Exported as `P0_API_TOKEN` in the environment.
    - Used by the Terraform `p0` provider to register and manage P0 integrations.

### Required environment variables

Set at least the following before running Terraform:

- **P0**
  - `P0_API_TOKEN` – API token generated in the P0 app for this org.

- **Okta**
  - `OKTA_API_PRIVATE_KEY` – PEM‑encoded private key used by the Okta service app for private key JWT auth.

- **AWS**
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - optional `AWS_SESSION_TOKEN`

### Configuration

The main configuration is provided via `terraform.tfvars` (not checked into git) and documented in `terraform.tfvars.example`.

At a high level you must configure:

- **Okta**
  - `okta.org_name` – your Okta org subdomain.
  - `okta.base_url` – Okta domain (for example `okta.com`).
  - `okta.tfauth.client_id` / `okta.tfauth.private_key_id` / `okta.tfauth.scopes` – match the Okta API service app that Terraform uses to authenticate (the app described in the **Okta** prerequisites above), not the P0 integration app that this repo creates.
  - `okta.native_app` – name and redirect URIs for the P0 login app (e.g. `app_redirect_uris = ["https://p0.app/oidc/auth/_redirect"]`).
  - `okta.api_integration_app.app_name` – label for the P0 Okta integration service app.

- **P0**
  - `p0.org_id` – the P0 organization identifier.
  - `p0.gcp_service_account_id` – GCP service account ID P0 uses to access AWS (see example).

- **AWS**
  - `identity_center_parent_account_id` – AWS account ID that hosts IAM Identity Center (org management or delegated admin account).
  - `aws.saml_identity_provider_name` – name of the existing SAML provider used for federation.
  - `aws.role_count` – number of AWS roles to pre‑provision.
  - `aws.group_key` – metadata key that P0 will use for routing (for example `environment`).
  - `regional_aws` – per‑region configuration including:
    - which VPCs are enabled (used for Systems Manager / SSH via SSM VPC endpoints)
    - which region is the Resource Explorer aggregator.
    - **Note:** This repo currently hard‑codes support for the `us-west-1` and `us-west-2` regions. To change regions you must:
      - add or update aliased `aws` providers in `main.tf` (for example `provider "aws" { alias = "eu_west_1" region = "eu-west-1" }`)
      - add corresponding `aws_p0_resource_access_*` and `aws_p0_ssm_documents_*` module blocks that use those provider aliases
      - update the `aws_systems_manager` module’s `providers` map and add matching `region_*` submodules under `modules/aws_systems_manager/modules/region`.

### Usage

1. **Clone this repository** and review `variables.tf` and `terraform.tfvars.example`.
2. **Create your own `terraform.tfvars`** (not committed) based on the example, filling in your Okta, P0, and AWS values.
3. **Export the required environment variables**:
   - `P0_API_TOKEN`, `OKTA_API_PRIVATE_KEY`, and AWS credentials.
4. **Initialize Terraform**:
   - `terraform init`
5. **Review the planned changes**:
   - `terraform plan`
6. **Apply** when ready:
   - `terraform apply`

After a successful apply, your Okta and AWS environments will be wired up so that P0 can:

- authenticate users via Okta
- read groups for policy routing
- manage AWS IAM integrations
- inventory resources
- enable SSH access through SSM
- evaluate sample routing rules for fine‑grained access control.

**Okta sign-in app:** Provide your Okta organization URL and the P0 login app’s **Client ID** to P0 (e.g. in the P0 app or to your P0 contact) so users can sign in with Okta. The Client ID is the `client_id` output of the `okta_native_login` module; you can add a root-level `output` that references `module.okta_native_login.client_id` and run `terraform output` to retrieve it. If you use Okta’s AWS Account Federation (Web SSO), configure this Client ID as the federation app’s **Allowed Web SSO Client**.

