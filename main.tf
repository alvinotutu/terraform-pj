provider "aws" {
    region = "eu-west-1"
}

/* USING MODULES PROVIDED BY TERRAFORM*/
/* We can reconfigure or customize the module however we want*/

module "vpc" {
    /* This source points to a module created by terraform in terraform registry
    This module will create so many other resources associated with vpc, including subnet, igw, route-table,
    associate route-table to subnet, etc.*/
    source = "terraform-aws-modules/vpc/aws"

    name = "my-vpc"
    cidr = var.vpc_cidr_block

    azs             = [var.avail_zone]
    public_subnets  = [var.subnet_cidr_block]

    public_subnet_tags = {
        Name = "${var.env_prefix}-subnet_1"
    }

    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

module "myapp-server" {
    source = "./modules/webserver"
    vpc_id = module.vpc.vpc_id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
    instance_type = var.instance_type
    subnet_id = module.vpc.public_subnets[0]
    avail_zone = var.avail_zone
}