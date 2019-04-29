resource "aws_lb" "tycho_master_nlb" {
  provider = "aws.ops"

  name                       = "${var.macluster}-${var.tychocluster}-api-nlb"
  load_balancer_type         = "network"
  enable_deletion_protection = false

  enable_cross_zone_load_balancing = true
  idle_timeout                     = 400

  subnets  = ["${data.aws_subnet_ids.ops_private.ids}"]
  internal = true

  access_logs {
    bucket  = "ma-auditlogs-int-${var.region}"
    prefix  = "${var.macluster}-${var.tychocluster}-api-nlb"
    enabled = true
  }

  tags = "${merge( map(
      "name", "${var.macluster}-${var.tychocluster}-api-nlb",
      "ma_env", "ops",
      "ma_cluster", "${var.macluster}",
      "ma_service", "tycho_master",
      "tycho_cluster_name", "kubernetes.io/cluster/${var.macluster}-${var.tychocluster}",
      "kubernetes.io/role/elb", "owned"
  ))}"
}

resource "aws_lb_listener" "tycho_master_nlb_api_listener" {
  provider          = "aws.ops"
  load_balancer_arn = "${aws_lb.tycho_master_nlb.arn}"
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tycho_master_api_tg.arn}"
  }
}

resource "aws_lb_listener" "tycho_master_nlb_kubelet_listener" {
  provider          = "aws.ops"
  load_balancer_arn = "${aws_lb.tycho_master_nlb.arn}"
  port              = "10250"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tycho_master_kubelet_tg.arn}"
  }
}

resource "aws_lb_target_group" "tycho_master_api_tg" {
  provider    = "aws.ops"
  name        = "tycho-${var.macluster}-${var.tychocluster}-nlb-6443-tg"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "${data.aws_vpc.ops_master_vpc.id}"
}

resource "aws_lb_target_group" "tycho_master_kubelet_tg" {
  provider    = "aws.ops"
  name        = "tycho-${var.macluster}-${var.tychocluster}-nlb-10250-tg"
  port        = 10250
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "${data.aws_vpc.ops_master_vpc.id}"
}

# The magic of 'count.index' does not work. The plan says it will add
# the correct number of targets, but then apply never actually creates.
# them. So this isn't very scalable and is a bug.
# https://github.com/terraform-providers/terraform-provider-aws/issues/7617
# resource "aws_lb_target_group_attachment" "tycho_master_api_tga" {
# provider = "aws.ops"
# count            = "${data.aws_instances.tycho_masters.count}"
# target_group_arn = "${aws_lb_target_group.tycho_master_api_tg.arn}"
# target_id        = "${element(data.aws_instances.tycho_masters.*.id, count.index)}"
# availability_zone  = "${element(data.aws_instances.tycho_masters.*.availability_zone, count.index)}"
# port             = 6443
# }

resource "aws_lb_target_group_attachment" "tycho_master_api0_tga" {
  provider         = "aws.ops"
  target_group_arn = "${aws_lb_target_group.tycho_master_api_tg.arn}"
  # target_id        = "${element(data.aws_instances.tycho_masters.*.id, 0)}"
  target_id        = "${data.aws_instances.tycho_masters.ids[0]}"
  port             = 6443
}

resource "aws_lb_target_group_attachment" "tycho_master_api1_tga" {
  provider         = "aws.ops"
  target_group_arn = "${aws_lb_target_group.tycho_master_api_tg.arn}"
  # target_id        = "${element(data.aws_instances.tycho_masters.*.id, 1)}"
  target_id        = "${data.aws_instances.tycho_masters.ids[1]}"
  port             = 6443
}

resource "aws_lb_target_group_attachment" "tycho_master_api2_tga" {
  provider         = "aws.ops"
  target_group_arn = "${aws_lb_target_group.tycho_master_api_tg.arn}"
  # target_id        = "${element(data.aws_instances.tycho_masters.*.id, 2)}"
  target_id        = "${data.aws_instances.tycho_masters.ids[2]}"
  port             = 6443
}

resource "aws_lb_target_group_attachment" "tycho_master_kubelet0_tga" {
  provider         = "aws.ops"
  target_group_arn = "${aws_lb_target_group.tycho_master_kubelet_tg.arn}"
  # target_id        = "${element(data.aws_instances.tycho_masters.*.id, 0)}"
  target_id        = "${data.aws_instances.tycho_masters.ids[0]}"
  port             = 10250
}

resource "aws_lb_target_group_attachment" "tycho_master_kubelet1_tga" {
  provider         = "aws.ops"
  target_group_arn = "${aws_lb_target_group.tycho_master_kubelet_tg.arn}"
  # target_id        = "${element(data.aws_instances.tycho_masters.*.id, 1)}"
  target_id        = "${data.aws_instances.tycho_masters.ids[1]}"
  port             = 10250
}

resource "aws_lb_target_group_attachment" "tycho_master_kubelet2_tga" {
  provider         = "aws.ops"
  target_group_arn = "${aws_lb_target_group.tycho_master_kubelet_tg.arn}"
  # target_id        = "${element(data.aws_instances.tycho_masters.*.id, 2)}"
  target_id        = "${data.aws_instances.tycho_masters.ids[2]}"
  port             = 10250
}

resource "aws_route53_record" "tycho_master_nlb_int_dn" {
  provider = "aws.ops"
  zone_id  = "${data.aws_route53_zone.internal_domain.id}"
  name     = "tycho-api-${var.tychocluster}"
  type     = "A"

  # ttl      = "300"
  # records  = ["${aws_lb.tycho_master_nlb.dns_name}"]
  alias {
    name                   = "${aws_lb.tycho_master_nlb.dns_name}"
    zone_id                = "${aws_lb.tycho_master_nlb.zone_id}"
    evaluate_target_health = true
  }
}
