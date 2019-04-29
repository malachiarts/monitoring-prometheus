#
# Prometheus AWS resources.
#
resource "aws_instance" "prometheus" {
  provider      = "aws.ops"
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "${var.prometheus_instance_type}"

  # availability_zone = "${data.aws_availability_zones.available.names[0]}"
  subnet_id              = "${element(data.aws_subnet_ids.ops_public.ids, count.index)}"
  vpc_security_group_ids = ["${data.aws_security_group.ops_jumpbox_sg.id}", "${aws_security_group.prometheus_security_group.id}"]

  associate_public_ip_address = true
  key_name  = "${var.ssh_key}"
  # key_name      = "${aws_key_pair.prometheus_key.key_name}"
  user_data = "${file("../modules/ops-prometheus/mount-ebs.sh")}"

  # With this as a separate resource, you can't auto-mount the block device.
  ebs_block_device {
    device_name = "${var.prometheus_data_device_name}"
    volume_type = "${var.prometheus_data_ebs_vol_type}"
    volume_size = "${var.prometheus_data_ebs_vol_size}"

    # delete on termination? no. we want to keep monitoring data.
    delete_on_termination = false
  }

  tags = {
    Name            = "${var.macluster}-ops-prometheus"
    malachi_cluster = "${var.macluster}"
    malachi_env     = "${var.maenv}"
    malachi_service = "prometheus"
  }
}

# resource "aws_key_pair" "prometheus_key" {
  # key_name   = "prometheus-key"
  # public_key = "${file("/Users/jbedard/.ssh/id_rsa.pub")}"
# }

resource "aws_security_group" "prometheus_security_group" {
  provider    = "aws.ops"
  name        = "prometheus_security_group"
  description = "Prometheus inbound traffic rules"
  vpc_id      = "${data.aws_vpc.ops_master_vpc.id}"

  tags = {
    Name            = "${var.macluster}-ops-prometheus-sg"
    malachi_cluster = "${var.macluster}"
    malachi_env     = "${var.maenv}"
    malachi_service = "prometheus"
  }
}

resource "aws_security_group_rule" "allow_ssh" {
  provider    = "aws.ops"
  description = "Prometheus Web UI Proxy"

  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  # TODO: might be issue
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.prometheus_security_group.id}"
}

resource "aws_security_group_rule" "allow_web_ui" {
  provider    = "aws.ops"
  description = "Prometheus Web UI Proxy"

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  # TODO: might be issue
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.prometheus_security_group.id}"
}

resource "aws_security_group_rule" "allow_outbound_traffic" {
  provider    = "aws.ops"
  description = "Prometheus Outbound Traffic"

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.prometheus_security_group.id}"
}

output "pd" {
  value = "$var.public_domain"
}

data "aws_route53_zone" "main" {
  provider = "aws.ops"
  name     = "${var.public_domain}."
}

resource "aws_route53_record" "ops-prometheus-ext" {
  provider = "aws.ops"
  zone_id  = "${data.aws_route53_zone.main.id}"
  name     = "prom-${var.macluster}-${var.tychocluster}"
  type     = "A"
  ttl      = "300"
  records  = ["${aws_instance.prometheus.public_ip}"]
}

# nice to have while debugging.
resource "aws_route53_record" "ops-prometheus-int" {
  provider = "aws.ops"
  zone_id  = "${data.aws_route53_zone.internal_domain.id}"
  name     = "prom1"
  type     = "A"
  ttl      = "300"
  records  = ["${aws_instance.prometheus.private_ip}"]
}
