provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-NLB2"
  }
}


resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.my_vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "PublicRouteTable"
  }
}


resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


resource "aws_route_table_association" "public_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_lb" "nlb" {
  name               = "MyNLB"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public_subnet[*].id
  enable_deletion_protection = false

  tags = {
    Name = "MyNLB"
  }
}


resource "aws_lb_target_group" "target_group" {
  name        = "MyTargetGroup"
  protocol    = "TCP"
  port        = 80
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "MyTargetGroup"
  }
}


resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}


resource "aws_instance" "my_instance" {
  count         = 2
  ami           = "ami-0df8c184d5f6ae949" # Replace with a valid AMI ID for your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "MyInstance-${count.index + 1}"
  }
}


resource "aws_lb_target_group_attachment" "target_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.my_instance[count.index].id
  port             = 80
}
