module "prometheus" {
  source = "../modules/ops-prometheus"
  region = "${var.region}"
  macluster = "${var.macluster}"
  tychocluster = "${var.tychocluster}"
  public_domain = "majustfortesting.com"
  ssh_key = "${var.ssh_key}"
}
