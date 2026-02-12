## p0-terraform-install

Deploy P0 integrations into an existing Okta + AWS environment using Terraform.

This module set is intended to bootstrap everything P0 needs to:

- Authenticate users via Okta
- Discover Okta groups
- Grant just-in-time access to AWS IAM permission sets and policies
- Grant just-in-time access to AWS resources
- Grant just-in-time SSH access to EC2 instances via AWS Systems Manager
- Define sample routing rules for fine‑grained access control in P0

### Integrations provided

- **Okta login** (`modules/okta_login`)
  - Creates a native Okta OIDC application used for sign-in to the P0 web app (e.g. https://p0.app) and the P0 CLI.
  - Uses PKCE and device / token‑exchange flows, with no client secret (`omit_secret = true`).

- **Okta group listing** (`modules/okta_group_listing`)
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
  - See [P0 SSH](https://docs.p0.dev/integrations/resource-integrations/ssh) for prerequisites, CLI usage, and configuring accounts.

- **Sample routing rules**
  - Provides example routing rules that show how P0 can:
    - map Okta groups, AWS attributes, and P0 metadata
    - enforce fine‑grained, just‑in‑time access patterns.
  - See [Just-in-time access](https://docs.p0.dev/orchestration/just-in-time-access) and [Integrations](https://docs.p0.dev/integrations/integrations) for more on access control.

### Prerequisites

- **Terraform**
  - **Terraform CLI** `1.8.0` (this repo pins `required_version = "= 1.8.0"`).
  - Recommended: [`tfenv`](https://github.com/tfutils/tfenv) to manage Terraform versions.

- **AWS**
  - An AWS account with:
    - IAM Identity Center (SSO) configured either on the account itself or on another account in its organization.
    - The user applying this terraform must have permission to create and manage:
      - IAM roles, policies, and SSM documents
      - Resource Explorer indexes and views.
  - Credentials exported via standard environment variables:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
    - optional `AWS_SESSION_TOKEN` for temporary credentials.

- **Okta**
  - An Okta org with API access enabled.
  - An Okta **API service app** (Client Credentials flow, private key JWT) that **Terraform** uses to create and manage Okta resources. You may use an **existing** API service app if your Okta account already has one with the required scopes. If not you can create a new one. This app is **distinct** from the Okta apps that this Terraform code will create for P0 (the P0 login native app and the P0 Okta integration service app).
    - **Required OAuth 2.0 scopes**:
      - `okta.roles.manage` – create custom admin roles and resource sets, and assign roles to apps
      - `okta.roles.read` – read roles and resource sets
      - `okta.apps.manage` – create and manage OAuth apps (the P0 login app and the P0 API integration app)
      - `okta.apps.read` – read app information
      - `okta.appGrants.manage` – grant scope consent to the API integration app (required for `okta_app_oauth_api_scope`); without this you may see "The access token provided does not contain the required scopes" when applying the okta_group_listing module
      - `okta.policies.read` and `okta.policies.manage` – the Okta provider reads/sets the default authentication (access) policy when managing OAuth apps; without these you may see “The access token provided does not contain the required scopes” when applying.
        For more information about these scopes, see [Okta OAuth 2.0 scopes](https://developer.okta.com/docs/api/oauth2/) and [Control Terraform access to Okta](https://developer.okta.com/docs/guides/terraform-design-access-security/main/).
    - **If creating a new app:** In the Okta Admin Console go to **Applications → Create App Integration → API Services → Enter a name for the app**.
    - **Regardless if you are using a new app of an existing one:** Add a public key and note the **client ID** and **private key ID**.
      Store the PEM‑encoded private key (starting with `-----BEGIN PRIVATE KEY-----`) in the `OKTA_API_PRIVATE_KEY` environment variable. You can export a PEM from the Okta UI or use the repo’s `jwk-to-pem.py` script if your key is in JWK form.
    - The list of scopes in your Terraform provider config (`okta.tfauth.scopes` in `terraform.tfvars`) must include at least the seven scopes above (and must match what the app is granted in Okta).

- **P0**
  - A P0 organization configured in the [P0 app](https://p0.app). See [P0 Onboarding](https://docs.p0.dev/p0-security-onboarding) for setup.
  - A **P0 API token** created in the P0 UI:
    - Exported as `P0_API_TOKEN` in the environment.
    - Used by the Terraform `p0` provider to register and manage P0 integrations.
  - **Note that to login to P0 the Okta login app must first be configured**. So this entire repository cannot be applied at one time. There are two steps in the process.
    - 1. Create an Okta Login app and coordinate with P0 to gain access to the P0 platform
    - 2. Once you are in the P0 platform, generate an API key and complete the subsequent installations of the Okta group listing integration as well as all of the AWS related setup

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

**Okta login app:** Provide your Okta organization URL and the P0 login app’s **Client ID** to P0 (e.g. in the [P0 app](https://p0.app) or to your P0 contact) so users can sign in with Okta. See [Directory integrations](https://docs.p0.dev/integrations/directory-integrations) and the [Okta integration](https://docs.p0.dev/integrations/directory-integrations/okta) for details. The Client ID is the `login_app_client_id` output of the `okta_login` module; you can add a root-level `output` that references `module.okta_login.login_app_client_id` and run `terraform output` to retrieve it. If you use Okta’s AWS Account Federation (Web SSO), configure this Client ID as the federation app’s **Allowed Web SSO Client**.

- **Okta** (two apps are created by this repo: a **login app** and a **group listing app**)
  - `okta.org_name` – your Okta org subdomain.
  - `okta.base_url` – Okta domain (for example `okta.com`).
  - `okta.tfauth.client_id` / `okta.tfauth.private_key_id` / `okta.tfauth.scopes` – match the Okta API service app that Terraform uses to authenticate (the app described in the **Okta** prerequisites above), not the P0 apps that this repo creates.
  - `okta.native_app` – name and redirect URIs for the **login app** (`modules/okta_login`), used for user sign-in to P0 (e.g. `app_redirect_uris = ["https://p0.app/oidc/auth/_redirect"]`).
  - `okta.api_integration_app.app_name` – label for the **group listing app** (`modules/okta_group_listing`), the service app P0 uses to list users and groups.

- **P0**
  - `p0.org_id` – the identifier for your tenant in P0 (find it in [p0.app](https://p0.app) or in the P0 URL, e.g. `https://p0.app/o/your-org-id`).

- **AWS**
  - `identity_center_parent_account_id` – AWS account ID that hosts IAM Identity Center. If you are using a delegated account, you must still provide the ID of the parent account here.
  - `aws.group_key` – Optional [grouping tag](https://docs.p0.dev/integrations/resource-integrations/ssh) for SSH (e.g. use with `p0 request ssh group --name <value>`).
  - `regional_aws` – per‑region configuration including:
    - which VPCs are enabled (used for Systems Manager / SSH via SSM VPC endpoints)
    - which region is the Resource Explorer aggregator.
    - **Note:** This repo currently hard‑codes support for the `us-west-1` and `us-west-2` regions. To change regions you must:
      - add or update aliased `aws` providers in `main.tf` (e.g. `provider "aws" { alias = "eu_west_1" region = "eu-west-1" }`)
      - update the `aws_resource_inventory` and `aws_ssh` module calls in `main.tf` to pass the new providers and extend `regional_aws` and each module’s regional configuration (e.g. `modules/aws_resource_inventory` and `modules/aws_ssh/systems_manager`).

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
