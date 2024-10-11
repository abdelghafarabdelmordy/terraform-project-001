# ---------------------------------------------
# VPC
# ---------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "cloudy-vpc"
  }
}

# ---------------------------------------------
# Subnets
# ---------------------------------------------
resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-subnet-2"
  }
}

# ---------------------------------------------
# Internet Gateway and NAT Gateway
# ---------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-internet-gateway"
  }
}

resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.subnet3.id
  tags = {
    Name = "nat-gateway"
  }
}

# ---------------------------------------------
# Route Tables and Associations
# ---------------------------------------------
resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "private_route" {
  route_table_id = aws_route_table.private_RT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "subnet1_association" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "subnet2_association" {
  subnet_id = aws_subnet.subnet2.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "subnet3_association" {
  subnet_id = aws_subnet.subnet3.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "subnet4_association" {
  subnet_id = aws_subnet.subnet4.id
  route_table_id = aws_route_table.public_RT.id
}

# ---------------------------------------------
# Security Groups
# ---------------------------------------------
resource "aws_security_group" "HTTP-SG" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "HTTP-security-group"
  }
}

resource "aws_security_group" "jumper-SG" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jumper-security-group"
  }
}

# ---------------------------------------------
# Load Balancer and Target Group
# ---------------------------------------------
resource "aws_lb" "app_lb" {
  name = "app-load-balancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.HTTP-SG.id]
  subnets = [aws_subnet.subnet3.id, aws_subnet.subnet4.id]
  enable_deletion_protection = false
  tags = {
    Name = "app-load-balancer"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name = "app-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  health_check {
    protocol = "HTTP"
    path = "/"
  }
  tags = {
    Name = "app-target-group"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ---------------------------------------------
# EC2 Instances and Key Pair
# ---------------------------------------------
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2_key"
  public_key = file("C:\\Users\\amordy\\.ssh/key.pub")
}

/*resource "aws_instance" "jumper_instance" {
  ami = "ami-0182f373e66f89c85"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet3.id
  vpc_security_group_ids = [aws_security_group.jumper-SG.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.ec2_key_pair.key_name
  tags = {
    Name = "jumper-server"
  }
}
*/
# ---------------------------------------------
# Fetch the Latest Amazon Linux 2023 AMI
# ---------------------------------------------
# ---------------------------------------------
# AMI Data Source for Amazon Linux 2023
# ---------------------------------------------
# ---------------------------------------------
# AMI Data Source for Amazon Linux 2023
# ---------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}


# ---------------------------------------------
# Create Jumper EC2 Instance
# ---------------------------------------------
resource "aws_instance" "jumper_instance" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet3.id
  vpc_security_group_ids      = [aws_security_group.jumper-SG.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ec2_key_pair.key_name
  tags = {
    Name = "jumper-server"
  }
}

# ---------------------------------------------
# S3 Bucket
# ---------------------------------------------
resource "aws_s3_bucket" "cloudy_s3" {
  bucket = "cloudy-service-s3-3001"
  force_destroy = true
  tags = {
    Name = "cloudy-service-s3-bucket"
  }
}

# ---------------------------------------------
# IAM Role, Policy, and Instance Profile
# ---------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_policy" {
  name = "s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::cloudy-service-s3-3001",
          "arn:aws:s3:::cloudy-service-s3-3001/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------------------------------
/*# Auto Scaling Group
# ---------------------------------------------
resource "aws_launch_configuration" "app" {
  name = "app-launch-configuration"
  image_id = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups = [aws_security_group.HTTP-SG.id]
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    echo "Hello, World from ASG, $(hostname -f)" > /home/ec2-user/index.html
    cd /home/ec2-user
    python3 -m http.server 80 &
  EOF
}

resource "aws_autoscaling_group" "app" {
  name = "app-asg"
  launch_configuration = aws_launch_configuration.app.id
  min_size = 1
  max_size = 3
  desired_capacity = 2
  vpc_zone_identifier = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  target_group_arns = [aws_lb_target_group.app_tg.arn]
  tag {
    key = "Name"
    value = "asg-instance"
    propagate_at_launch = true
  }
}
*/
# ---------------------------------------------
# Launch Template for Auto Scaling Group
# ---------------------------------------------
# ---------------------------------------------
# Launch Template for Auto Scaling Group
# ---------------------------------------------
# ---------------------------------------------
# Launch Template for Auto Scaling Group
# ---------------------------------------------
resource "aws_launch_template" "app" {
  name_prefix   = "app-launch-template"
  image_id      = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  vpc_security_group_ids = [aws_security_group.HTTP-SG.id]
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    echo "Hello, World from ASG, $(hostname -f)" > /home/ec2-user/index.html
    cd /home/ec2-user
    python3 -m http.server 80 &
  EOF
  )
}

# ---------------------------------------------
# Auto Scaling Group with Launch Template
# ---------------------------------------------
resource "aws_autoscaling_group" "app-as" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  target_group_arns    = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}

