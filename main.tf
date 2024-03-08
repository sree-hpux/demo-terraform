provider "aws" {

  region     = "us-east-1"
  access_key = "AKIAYIQ7TQ4KSGPPCBNT"
  secret_key = "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"

}
variable "cidr" {
  default = "10.0.0.0/16"

}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

}
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.RT.id

}
resource "aws_security_group" "websg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow SSH"
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
    name = "websg"
  }
}
resource "aws_instance" "server" {
  ami                    = "ami-07d9b9ddc6cd8dd30"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.subnet1.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:/users/SRIKANTH/.ssh/id_rsa")
    host        = self.public_ip

  }

  #File provisioner to copy file from local to remote system
provisioner "file" {
    source      = "app.py"
    destination = "/home/ubuntu/app.py"

  }
provisioner "remote-exec" {
    inline = [
      "echo 'Hello from server'",
      "sudo apt get update -y",
      "sudo apt get install -y python3-pip",
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py",
    ]

  }
}