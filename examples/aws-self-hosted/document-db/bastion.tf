# The Ubuntu server AMI contains the Amazon SSM agent pre-installed
# See https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.12-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_iam_policy_document" "bastion_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  count = var.bastion ? 1 : 0

  name               = "${local.cluster_name}-bastion"
  description        = "IAM instance profile for ${local.cluster_name}-bastion"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_role.json
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count = var.bastion ? 1 : 0

  role       = aws_iam_role.bastion[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.bastion ? 1 : 0

  name = "${local.cluster_name}-bastion"
  role = aws_iam_role.bastion[0].name
}

resource "aws_security_group" "bastion" {
  #checkov:skip=CKV2_AWS_5: False positive
  count = var.bastion ? 1 : 0

  name        = "${local.cluster_name}-bastion"
  vpc_id      = var.vpc_id
  description = "Security group for DocumentDB bastion"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ingress" {
  count = var.bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  cidr_ipv4         = data.aws_vpc.current.cidr_block
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH access from the VPC"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ingress_self" {
  count = var.bastion ? 1 : 0

  security_group_id            = aws_security_group.bastion[0].id
  referenced_security_group_id = aws_security_group.bastion[0].id
  ip_protocol                  = "-1"
  description                  = "All traffic within the security group"
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_ipv4" {
  count = var.bastion ? 1 : 0

  description       = "Allow outbound access"
  security_group_id = aws_security_group.bastion[0].id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_ipv6" {
  count = var.bastion ? 1 : 0

  description       = "Allow outbound access"
  security_group_id = aws_security_group.bastion[0].id

  cidr_ipv6   = "::/0"
  ip_protocol = "-1"
}

# The key pair is for break-glass / backup access to the bastion host.
resource "aws_instance" "bastion_instance" {
  #checkov:skip=CKV2_AWS_41: Not needed for this use-case
  count = var.bastion ? 1 : 0

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  ebs_optimized = true
  root_block_device {
    encrypted = true
  }

  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion[0].id]

  monitoring = true
  # Address CKV_AWS_79 & CKV_AWS_126 – IMDSv2
  metadata_options {
    http_tokens   = "required" # IMDSv2 only
    http_endpoint = "enabled"
  }

  iam_instance_profile = aws_iam_instance_profile.bastion[0].name

  tags = {
    Name = "${local.cluster_name}-bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_bastion_ingress" {
  count = var.bastion ? 1 : 0

  description                  = "Allow access to ${local.cluster_name} from bastion"
  security_group_id            = aws_security_group.docdb.id
  referenced_security_group_id = aws_security_group.bastion[0].id
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}
