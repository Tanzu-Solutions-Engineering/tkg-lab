provider "aws" {
  region = var.aws_region
}

locals {
  name = "ex-${replace(basename(path.cwd), "_", "-")}"

  tags = {
    Name = "TKGVPC"
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = local.name
  cidr = "172.16.0.0/16"

  azs             = ["${var.aws_region}a"]
  private_subnets = ["172.16.0.0/24"]
  public_subnets  = ["172.16.3.0/24"]

  enable_ipv6 = false

  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true

  igw_tags = {
    "Name" = "tkg-inet-gw"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/${var.mc_name}"  = "shared"
    "kubernetes.io/cluster/${var.ssc_name}" = "shared"
    "kubernetes.io/cluster/${var.wlc_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/${var.mc_name}"  = "shared"
    "kubernetes.io/cluster/${var.ssc_name}" = "shared"
    "kubernetes.io/cluster/${var.wlc_name}" = "shared"
  }

  public_subnet_tags_per_az = {
    "${var.aws_region}a" = {
      "Name" = "pub-a"
    }
  }

  private_subnet_tags_per_az = {
    "${var.aws_region}a" = {
      "Name" = "priv-a"
    }
  }

  tags = local.tags

}

