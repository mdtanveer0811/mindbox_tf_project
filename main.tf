terraform {

  backend "s3" {
    bucket = "s3-bucket-tf"
    key    = "path/terraform.tfstate"
    region = "ap-south-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

#key_pair
resource "aws_key_pair" "key_tf" {
  key_name   = "key_tf"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC07xI/puLnD2YPHZdNj3lqeN3XAlooyp5w4mTAAIsQt580kVoHTQ2uO+ayLQ2cHCtqXlZY3ATwaJdQUy5UmIh5ySDGHrJZtqwvjgRheXIM/tWLgL339k2BdNTU8BfdIo02lKp6fIMivnW0ZJEkUni/op335EjrQViF+wusyU92OASElqt1TkyDeRvu70oeHXUcXe4QkqvzRU49Fa0e+1VdrJ/36heBovQ9CFEyYaeFFwTn0nJ6h3NMRIhOkSsG0FSRDlHjO03aC+fDgzDkLXnwYzm2g5ssvELQ4n8dXxCBi0JnUcBYWTc7jhgP1pskSwKX3sjqau8HFJ29S58DO2MJ3Kq5bSeTr+owKPvaYAjSx1+Cx94D0QsUgAatn24vtLZXbfeD47LvwvHCG3/Vi2boMB30xW6ILyMnW8jeuollx0iScL/7EkZgIDjot2HZx40eHa6yJqaDJT9a0FhcVO646vYIf3UBP5xbqM/uZ2PUkaFS8jGI/xodoTmZiyD6gIc= aasuz@DESKTOP-MOLP664"
  
  tags = {
    Name = "key_tf"
  }
}

#vpc
resource "aws_vpc" "vpc_tf" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "vpc_tf"
  }
}

#security_group
resource "aws_security_group" "sg_tf" {
  name        = "sg_tf"
  description = "allow ssh and http"
  vpc_id      = aws_vpc.vpc_tf.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sg_tf"
  }
}

#subnets
resource "aws_subnet" "subnet_1a_public_tf" {
  vpc_id     = aws_vpc.vpc_tf.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "subnet_1a_public_tf"
  }
}

resource "aws_subnet" "subnet_1a_private_tf" {
  vpc_id     = aws_vpc.vpc_tf.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "subnet_1a_private_tf"
  }
}

resource "aws_subnet" "subnet_1b_public_tf" {
  vpc_id     = aws_vpc.vpc_tf.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "subnet_1b_public_tf"
  }
}

resource "aws_subnet" "subnet_1b_private_tf" {
  vpc_id     = aws_vpc.vpc_tf.id
  cidr_block = "10.10.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "subnet_1b_private_tf"
  }
}

#internet_gateway
resource "aws_internet_gateway" "igw_tf" {
  vpc_id = aws_vpc.vpc_tf.id

  tags = {
    Name = "igw_tf"
  }
}

#route_tables
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc_tf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_tf.id
  }

  tags = {
    Name = "rt_public"
  }
}

resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.vpc_tf.id

  tags = {
    Name = "rt_private"
  }
}

#route_table association
resource "aws_route_table_association" "rta_public_1a" {
  subnet_id      = aws_subnet.subnet_1a_public_tf.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rta_private_1a" {
  subnet_id      = aws_subnet.subnet_1a_private_tf.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table_association" "rta_public_1b" {
  subnet_id      = aws_subnet.subnet_1b_public_tf.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rta_private_1b" {
  subnet_id      = aws_subnet.subnet_1b_private_tf.id
  route_table_id = aws_route_table.rt_private.id
}

#target_group
resource "aws_lb_target_group" "tg_tf" {
  name     = "tgtf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_tf.id
}

#load_balancer
resource "aws_lb" "lb_tf" {
  name               = "lbtf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_tf.id]
  subnets            = [aws_subnet.subnet_1a_public_tf.id, aws_subnet.subnet_1b_public_tf.id]
}

#load_balancer_listener
resource "aws_lb_listener" "lbl_tf" {
  load_balancer_arn = aws_lb.lb_tf.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_tf.arn
  }
}

#launch_template
resource "aws_launch_template" "lt_tf" {
  name = "lt_tf"

  image_id = "ami-0f5ee92e2d63afc18"

  instance_type = "t2.micro"

  key_name = aws_key_pair.key_tf.id

  vpc_security_group_ids = [aws_security_group.sg_tf.id]

  user_data = filebase64("example.sh")
}

#auto_scaling_group
resource "aws_autoscaling_group" "asg_tf" {
  vpc_zone_identifier =  [aws_subnet.subnet_1a_public_tf.id, aws_subnet.subnet_1b_public_tf.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  name = "asg_tf"
  target_group_arns = [aws_lb_target_group.tg_tf.arn]

  launch_template {
    id      = aws_launch_template.lt_tf.id
    version = "$Latest"
  }
}