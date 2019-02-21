variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  default = "tycho"
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  default = "t2.xlarge"
}

variable "ebs_size" {
  description = "Size of the EBS volume to be attached to Prometheus instances."
  default = 250
}

# MA Specific Default
variable "subnet_id" {
  description = "AWS subnet to launch resources."
  # default = "subnet-0eb3d4ec7a9a170e3"
  default = "subnet-8ec543c5" # jenkins
}

# MA Specific Default
variable "vpc_id" {
  description = "AWS VPC to launch resrouces."
  # default = "vpc-08ff1b19cfc8260d3"
  default = "vpc-61555418" # jenkins
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  default = 1
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  default = 1
}
