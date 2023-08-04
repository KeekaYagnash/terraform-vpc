provider "aws" {
  region     = "us-east-1"
}

#  1. Create VPC 
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "production" }
}
# ...

#  2. Create Internet Gateway
resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.prod_vpc.id
  tags   = { Name = "my_gateway" }
}
# ...

#  3. Create Custom Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = "my_route_table"
  }
}
# ...

#  4. Create a Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "prod_subnet" }
}
# ...

#  5. Associate subnet with route table
resource "aws_route_table_association" "route_table_ass" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}
# ...

#  6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_tls"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web-traffic"
  }
}
# ...

#  7. Create a network interface with ip in the subnet that was created in step 4
resource "aws_network_interface" "web_server_yk" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]

}
# ...

#  8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = "true"
  network_interface         = aws_network_interface.web_server_yk.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.my_gateway]
}
# ...

#  9. Create Ubuntu server and install/enable apache 2
resource "aws_instance" "web_server_instance" {
  ami               = "ami-0f34c5ae932e6f0e4"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "tfkeypair"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_yk.id
  }
  #   Starts exe the comands on "-EOF" and ends all comands on "EOF"
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF

  tags = { Name = "web-server" }
}

# ...

# resource "aws_instance" "my-first-server" {
#   ami           = "ami-0f34c5ae932e6f0e4"
#   instance_type = "t2.micro"
#   tags = {
#     Name : "my-first-terraform-test"
#   }
# }

# resource "aws_vpc" "my-first-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "prod_vpc"
#   }

# }

# resource "aws_subnet" "my_subnet-1" {
#   vpc_id     = aws_vpc.my-first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }

# }

# resource "aws_subnet" "second-subnet" {
#   vpc_id     =aws_vpc.my-second-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-2-two-subnet"
#   }

# }

# resource "aws_vpc" "my-second-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "prod_two_2_vpc"
#   }

# }