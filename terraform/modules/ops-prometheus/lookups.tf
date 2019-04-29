provider "aws" {
  alias   = "ops"
  region  = "${var.region}"
  profile = "malachiarts"
}

data "aws_instances" "tycho_masters" {
  provider = "aws.ops"

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  filter {
    name   = "tag:Cluster"
    values = ["Tycho"]
  }

  filter {
    name   = "tag:Role"
    values = ["master"]
  }

  # filter {
    # name = "tag:Name"
    # values = ["tycho-master*"]
  # }
}

data "aws_route53_zone" "internal_domain" {
  provider = "aws.ops"
  name     = "${var.macluster}.${var.public_domain}."
  # vpc_id   = "${data.aws_vpc.ops_master_vpc.id}"
  private_zone = true
}

data "aws_vpc" "ops_master_vpc" {
  provider = "aws.ops"

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.macluster}-vpc", "BaseNetworkVPC"]
  }
}

# Name: tycho-us-west-2a-public
# RouteTable: tycho-routetable-public
data "aws_subnet_ids" "ops_public" {
  provider = "aws.ops"

  vpc_id = "${data.aws_vpc.ops_master_vpc.id}"

  filter {
    name   = "tag:Name"
    values = ["${var.macluster}-${var.region}*-public"]
  }
}

data "aws_subnet_ids" "ops_private" {
  provider = "aws.ops"
  vpc_id   = "${data.aws_vpc.ops_master_vpc.id}"

  tags {
    subnet_type = "private"
  }
}

data "aws_subnet" "ops_private" {
  provider = "aws.ops"
  count    = "${length(data.aws_subnet_ids.ops_private.ids)}"
  id       = "${data.aws_subnet_ids.ops_private.ids[count.index]}"
}

# tycho has a single security group.
data "aws_security_group" "ops_jumpbox_sg" {
  provider = "aws.ops"

  name   = "${var.macluster}-securitygroup"
  vpc_id = "${data.aws_vpc.ops_master_vpc.id}"
}

data "aws_availability_zones" "available" {
  provider = "aws.ops"
}

data "aws_ami" "centos" {
  provider    = "aws.ops"
  most_recent = true
  owners      = ["679593333241"] # CentOS.org

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
