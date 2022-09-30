provider "aws" {
    region = "eu-west-1"
}

variable "cidr_blocks" {
    description = "List of cidr blocks"
    type = list(object({
        cidr_block = string,
        name = string}))
}

variable "vpc_tag" {
    description = "tag for VPC"
    default = "my_vpc"
}

variable "subnet_tag" {
    description = "tag for VPC"
    default = "my_vpc_subnet"
}


resource "aws_vpc" "terraform-vpc" {
    cidr_block = var.cidr_blocks[0].cidr_block
    tags = {
        Name: var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "terraform-subnet-A" {
    vpc_id = aws_vpc.terraform-vpc.id
    cidr_block = var.cidr_blocks[1].cidr_block
    availability_zone = "eu-west-1a"
    tags = {
        Name: var.cidr_blocks[1].name
    }
}

output "terraform-vpc-id" {
    value = aws_vpc.terraform-vpc.id
}

output "terraform-vpc-arn" {
    value = aws_vpc.terraform-vpc.arn
}

output "terraform-subnet-A-id" {
    value = aws_subnet.terraform-subnet-A.id
}

output "terraform-subnet-A-arn" {
    value = aws_subnet.terraform-subnet-A.arn
}