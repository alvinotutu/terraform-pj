provider "aws" {
    region = "eu-west-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable env_prefix {}
variable "my_ip" {}
variable instance_type {}
variable public_key_location {}
variable private_key_location {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-a"
    }
}

/* resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        gateway_id = aws_internet_gateway.myapp-igw.id
        cidr_block = "0.0.0.0/0"
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
} */

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

/* resource "aws_route_table_association" "myapp-subnet-rtb-assoc" {
    subnet_id = aws_subnet.myapp-subnet.id
    route_table_id = aws_route_table.myapp-route-table.id
} */

/* Use main route table created by AWS when we created this VPC*/
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}

/*
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-myapp-sg"
    }
} */

/* Use default security group created by AWS when we created this VPC*/

resource "aws_default_security_group" "default-myapp-sg" {
    vpc_id = aws_vpc.myapp-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

output "aws_instance_ip" {
    value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
    key_name = "tf-created-key"
    public_key = "${file(var.public_key_location)}"
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id 
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet.id
    vpc_security_group_ids = [aws_default_security_group.default-myapp-sg.id]
    availability_zone = var.avail_zone

    key_name = aws_key_pair.ssh-key.key_name 
    associate_public_ip_address = true

    /* user_data = file("entry-script.sh") */

    /* We may use "provisioner "remote-exec" " to run commands in our created instance, instead of using user_data*/
    /* However we must first use the "provisioner "file" " to copy the bash script from our local machine 
    to the instance*/
    /* We may also write inline instead of using a bash script file*/
    /* However, before terraform can run these commands, or copy the bash files in the instance, 
    it must first connect into the instance with "connection" */

    connection {
        type ="ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = file(var.private_key_location)
    }

    /* TERRAFFORM ADVISES AGAINTS USING PROVISIONERS, EXCEPT AS A LAST RESORT*/
    /* Tools like ANSIBLE, PUPPET OR CHEF should be used for configuration management*/
    /* Terraform does not have any control over commands run with provisioners and can thus give
    no status feedback on these commands or scripts*/

    provisioner "file" {
        source = "entry-script.sh"
        destination = "home/ec2-user/entry-script-on-ec2.sh"
    }

    provisioner "remote-exec" {
        script = file("entry-script-on-ec2.sh")
    }

    /* We can also use provisioner to run commands locally with "provisioner "local-exec" ""*/
    /* We may output the comman to a file "output.txt" */

    provisioner "local-exec" {
        command = "echo ${self.public_ip} > output.txt"
    }

    tags = {
        Name: "${var.env_prefix}-server"
    }
}