#
# These configure the global state storage and standard providers
#
terraform {
  backend "s3" {
    bucket  = "ma-tycho-terraform-states"
    region  = "us-west-2"
    encrypt = "true"
    profile = "malachiarts"
  }
}

# Provider for the local environment resources
#
provider "aws" {
  version = "< 2.0.0"
  region  = "${var.region}"
  profile = "malachiarts"
}

# Same thing, with a usable alias
#
provider "aws" {
  alias   = "primary"
  version = "< 2.0.0"
  region  = "${var.region}"
  profile = "malachiarts"
}

# Provider for central "ops" resources, Route53, etc.
#
provider "aws" {
  alias   = "main"
  version = "< 2.0.0"
  region  = "${var.region}"
  profile = "malachiarts"
}

# Provider for explicitly US-based "ops" resources.
provider "aws" {
  alias   = "us1"
  version = "< 2.0.0"
  region  = "us-west-2"
  profile = "malachiarts"
}
