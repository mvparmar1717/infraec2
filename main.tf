provider "aws" {
	access_key = "AKIAYDSLAPXL2AVHITHQ"
	secret_key = "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"
	region     = "ap-south-1"
	}

#create the VPC 
resource "aws_vpc" "vpctest" {
	cidr_block = "10.0.0.0/16"
	tags = {
	  Name = "prodvpc"
	}
  
}

#create internet gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpctest.id

  tags = {
    Name = "prodgw"
  }
}

#create custom route table
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.vpctest.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block  = "::/0"
    gateway_id       = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prodrt"
  }
}

#create the Sub-net
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.vpctest.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
	Name = "prodsubnet"
  }
}

#associate subnet with route table
resource "aws_route_table_association" "subroutetab" {
	subnet_id = aws_subnet.subnet-1.id
	route_table_id = aws_route_table.routetable.id 
	  
}

#create security group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpctest.id

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
    Name = "allow_web"
  }
}

#create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "webservernic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.17"]
  security_groups = [aws_security_group.allow_web.id]

}

#assing an elastic ip to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webservernic.id 
  associate_with_private_ip = "10.0.1.17"
  depends_on                = [aws_internet_gateway.gw]
}

#create ubuntu server and install/enable apache2
resource "aws_instance" "webserverinstance" {
  ami = "ami-03f0fd1a2ba530e75"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "terrakey"

  network_interface {
	device_index = 0
	network_interface_id = aws_network_interface.webservernic.id
  }

user_data = <<-EOF
		          #! /bin/bash
              sudo apt-get update
		          sudo apt-get install -y apache2
		          sudo systemctl start apache2
		          sudo systemctl enable apache2
		          echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
	            EOF
	tags = {
		Name = "webserverinstance"	
		Batch = "5AM"
	}
  

  /* user_data = <<-EOF
               #! /bin/bash
			         sudo apt update -y
			         sudo apt install apache2 -y 
			         sudo systemctl start apache2
			         sudo bash -c 'echo your every first server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  } */
}














































/* resource "aws_instance" "terraform_test"{
    ami			  = "ami-052c08d70def0ac62"
	instance_type = "t2.micro"
    
	tags = {
		Name ="ec2_terraform"
	} 
}*/
/* resource "<provider>_<resource_type>" "name" {
	configure
} */
