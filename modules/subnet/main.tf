resource "aws_subnet" "myapp-subnet" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-a"
    }
}

/* resource "aws_route_table" "myapp-route-table" {
    vpc_id = var.vpc_id
    route {
        gateway_id = aws_internet_gateway.myapp-igw.id
        cidr_block = "0.0.0.0/0"
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
} */

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = var.vpc_id
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
    default_route_table_id = var.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}
