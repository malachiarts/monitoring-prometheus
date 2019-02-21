#
# TODO: implement remote state.
# TODO: need a Role??
# TODO: use CR's `key_name`.
# TODO: [PROD] remove aws_key_pair.
# TODO: [PROD] remove delete_on_termination for the ESB in AWS_INSTANCE.
# TODO: [PROD] remove associate_public_ip_address for AWS_INSTANCE.
# TODO: [PROD] remove SSH ingress rule.
# TODO: may need to build an ALB/ELB?
#
terraform {
  required_version = ">= 0.9, < 0.11.3"
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "prometheus" {
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "${var.instance_type}"

  availability_zone = "${data.aws_availability_zones.all.names[0]}"
  subnet_id         = "${var.subnet_id}"
  security_groups   = ["${aws_security_group.prometheus_security_group.id}"]

  # doubt we'll use a public IP for CR.
  associate_public_ip_address = true
  key_name      = "${aws_key_pair.prometheus_key.key_name}"
  user_data     = "${file("./mount-ebs.sh")}"

  # With this as a separate resource, you can't auto-mount the block device.
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp2"
    volume_size = "${var.ebs_size}"
    # delete on termination?
    delete_on_termination = true
  }

  tags = {
    Name = "Prometheus Instance"
    User = "jb"
  }
}

# resource "aws_ebs_volume" "prometheus_ebs" {
  # availability_zone = "${data.aws_availability_zones.all.names[0]}"
  # size              = "${var.ebs_size}"
  # type              = "gp2"
  # tags = {
    # Name = "Prometheus EBS Storage"
    # User = "jb"
  # }
# }

# resource "aws_volume_attachment" "ebs_att" {
  # device_name = "/dev/sdb"
  # volume_id   = "${aws_ebs_volume.prometheus_ebs.id}"
  # instance_id = "${aws_instance.prometheus.id}"
  # skip_destroy = true
# }

resource "aws_key_pair" "prometheus_key" {
  key_name   = "prometheus-key"
  public_key = "${file("/Users/jbedard/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "prometheus_security_group" {
  name        = "prometheus_security_group"
  description = "Prometheus inbound traffic rules"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name = "Prometheus Security Group"
    User = "jb"
  }
}

resource "aws_security_group_rule" "allow_ssh" {
  description = "Allow ssh inbound traffic"

  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.prometheus_security_group.id}"
}

resource "aws_security_group_rule" "allow_web_ui" {
  description = "Prometheus Web UI Proxy"

  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.prometheus_security_group.id}"
}

resource "aws_security_group_rule" "allow_outbound_traffic" {
  description = "Outbound Traffic"

  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.prometheus_security_group.id}"
}

data "aws_availability_zones" "all" {}

data "aws_ami" "centos" {
  most_recent = true
  owners      = ["679593333241"] # Canonical

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
