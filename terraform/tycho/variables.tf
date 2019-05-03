variable "region" {}
variable "macluster" {}
variable "maenv" { default = "ops" }
variable "tychocluster" { default = "test" }

variable "ssh_key" {
  # default = "jb-pub-key"
  default = "ReferencePlatform"
}
