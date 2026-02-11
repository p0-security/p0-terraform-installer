data "aws_caller_identity" "current" {}

locals {
  role_name        = "P0RoleIamManager"
  policy_name      = "P0RoleIamManagerPolicy"
  account_id       = data.aws_caller_identity.current.account_id
  parent_account_id = var.identity_center_parent_account_id
  tags = {
    managed-by = "terraform"
    used-by    = "P0Security"
  }
}

resource "aws_iam_role" "p0_iam_role" {
  name = local.role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "accounts.google.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "accounts.google.com:aud": "${var.gcp_service_account_id}"
        }
      }
    }
  ]
}
EOF

  inline_policy {
    name = local.policy_name

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "P0CanGetAndListPolicies",
      "Effect": "Allow",
      "Action": [
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyTags",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "P0CanManagePoliciesAndListResources",
      "Effect": "Allow",
      "Action": [
        "account:ListRegions",
        "iam:AddUserToGroup",
        "iam:AttachRolePolicy",
        "iam:AttachUserPolicy",
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:DetachUserPolicy",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:GetSAMLProvider",
        "iam:GetUser",
        "iam:ListAccountAliases",
        "iam:ListAttachedGroupPolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListAttachedUserPolicies",
        "iam:ListGroupPolicies",
        "iam:ListGroups",
        "iam:ListGroupsForUser",
        "iam:ListPolicies",
        "iam:ListRolePolicies",
        "iam:ListRoles",
        "iam:ListUsers",
        "iam:ListUserTags",
        "iam:PutRolePolicy",
        "iam:RemoveUserFromGroup",
        "ec2:DescribeInstances",
        "resource-explorer-2:ListIndexes",
        "resource-explorer-2:Search",
        "sagemaker:ListNotebookInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceAccount": "${local.account_id}"
        }
      }
    },
    {
      "Sid": "P0CanManageSshAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "ssm:AddTagsToResource",
        "ssm:GetDocument",
        "ssm:DescribeInstanceInformation",
        "ssm:DescribeSessions",
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations",
        "ssm:TerminateSession"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceAccount": "${local.account_id}"
        }
      }
    },
    {
      "Sid": "P0CanUseSsmDocsForSshAccess",
      "Effect": "Allow",
      "Action": "ssm:SendCommand",
      "Resource": [
        "arn:aws:ec2:*:${local.account_id}:instance/*",
        "arn:aws:ssm:*:${local.account_id}:document/P0ProvisionUserAccess",
        "arn:aws:ssm:*:${local.account_id}:document/P0GetSshHostKeys"
      ]
    },
    {
      "Sid": "P0CanManageKubernetesAccess",
      "Effect": "Allow",
      "Action": [
        "eks:CreateAccessEntry",
        "eks:DeleteAccessEntry",
        "eks:DescribeAccessEntry",
        "eks:UpdateAccessEntry"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceAccount": "${local.account_id}"
        },
        "ArnNotLike": {
          "eks:principalArn": "arn:aws:iam::${local.account_id}:role/P0Role*"
        }
      }
    },
    {
      "Sid": "P0CanManageSsoAssignments",
      "Effect": "Allow",
      "Action": [
        "iam:GetSAMLProvider",
        "identitystore:ListUsers",
        "sso:AttachCustomerManagedPolicyReferenceToPermissionSet",
        "sso:AttachManagedPolicyToPermissionSet",
        "sso:CreateAccountAssignment",
        "sso:CreatePermissionSet",
        "sso:DeleteAccountAssignment",
        "sso:DeletePermissionSet",
        "sso:DescribeAccountAssignmentCreationStatus",
        "sso:DescribeAccountAssignmentDeletionStatus",
        "sso:DescribePermissionSet",
        "sso:DescribePermissionSetProvisioningStatus",
        "sso:GetInlinePolicyForPermissionSet",
        "sso:ListAccountAssignments",
        "sso:ListInstances",
        "sso:ListManagedPoliciesInPermissionSet",
        "sso:ListCustomerManagedPolicyReferencesInPermissionSet",
        "sso:ListPermissionSets",
        "sso:ListTagsForResource",
        "sso:ProvisionPermissionSet",
        "sso:PutInlinePolicyToPermissionSet",
        "sso:ListAccountsForProvisionedPermissionSet"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceAccount": ["${local.account_id}", "${local.parent_account_id}"]
        }
      }
    },
    {
      "Sid": "P0CanCreateSsoRolesOnly",
      "Effect": "Allow",
      "Action": "iam:CreateRole",
      "Resource": "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/*"
    },
    {
      "Sid": "P0CanTagPoliciesAndRoles",
      "Effect": "Allow",
      "Action": [
        "iam:CreatePolicy",
        "iam:TagPolicy"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/P0Security": "Managed by P0",
          "aws:ResourceAccount": "${local.account_id}"
        }
      }
    },
    {
      "Sid": "P0CanNotAlterItsOwnRole",
      "Effect": "Deny",
      "Action": [
        "iam:AttachRole*",
        "iam:DeleteRole*",
        "iam:DetachRole*",
        "iam:PutRole*",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateRole*"
      ],
      "Resource": "arn:aws:iam::${local.account_id}:role/P0Role*"
    },
    {
      "Sid": "P0CannotAlterSsmDocuments",
      "Effect": "Deny",
      "Action": [
        "ssm:CreateDocument",
        "ssm:DeleteDocument",
        "ssm:UpdateDocument"
      ],
      "Resource": [
        "arn:aws:ssm:*:${local.account_id}:document/P0ProvisionUserAccess",
        "arn:aws:ssm:*:${local.account_id}:document/P0GetSshHostKeys"
      ]
    },
    {
      "Sid": "P0CanNotAssumeRoles",
      "Effect": "Deny",
      "Action": "sts:AssumeRole",
      "Resource": "*"
    }
  ]
}
EOF
  }

  tags = local.tags
}
