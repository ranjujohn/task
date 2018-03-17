provider "aws" {
  region = "eu-central-1"
}
resource "aws_key_pair" "mykey"
{
  key_name = "key1"
  public_key = "${file("ssh_keys/tmp-key.pub")}"
}
resource "aws_security_group" "allow_https" {
  name = "allow_https"
    description = "Allow Https"
  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "web-server" {
  ami = "ami-7c412f13"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_https.id}"]
  key_name = "key1"
  user_data = <<EOF
#!/bin/bash
git clone https://github.com/ranjujohn/task.git
cd task
chmod +x install_new.sh
sudo ./install_new.sh
EOF
  tags {
    Name = "web-server"
  }
}
