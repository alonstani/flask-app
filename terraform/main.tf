provider "aws" {
  region = "us-east-1"  # Make sure this is the correct region
}

resource "aws_instance" "web" {
  ami           = "ami-04e8b3e527208c8cf"  # Latest Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  key_name      = "inyouk-key"

  security_groups = ["as_instance-sg"]  # Your existing security group

  tags = {
    Name = "web-instance"
  }

  user_data = <<-EOF
               #!/bin/bash
               yum update -y
               amazon-linuxextras install docker-y
               service docker start
               usermod -a -G docekr ec2-user
               curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
               chmod +x /usr/local/bin/docker-compose
               git clone https://github.com/alonstani/flask-app
               cd ~/flask-app
               docker-compose up -d
               EOF

}



