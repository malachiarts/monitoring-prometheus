variable "region" {}
variable "macluster" {}
variable "ssh_key" {}

variable "maenv" {
  default = "ops"
}

variable "tychocluster" {}
variable "public_domain" {}

variable "prometheus_instance_type" {
  default = "t2.xlarge"
}

variable "prometheus_data_device_name" {
  default = "/dev/sdc"
}

variable "prometheus_data_ebs_vol_size" {
  default = "250"
}

variable "prometheus_data_ebs_vol_type" {
  default = "gp2"
}
