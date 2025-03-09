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
               # Update the instance
               sudo yum update -y

               # Install Docker
               sudo amazon-linux-extras install docker -y
               sudo systemctl enable docker
               sudo systemctl start docker

               # Add the ec2-user to the docker group
               sudo usermod -a -G docker ec2-user

               # Install Docker Compose
               sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
               sudo chmod +x /usr/local/bin/docker-compose
               sudo yum install git -y
               git --version
               # Clone the Flask app from GitHub
               git clone https://github.com/alonstani/flask-app /home/ec2-user/flask-app

               # Change to the Flask app directory
               cd ~/flask-app

               # Build and start the Flask app using Docker Compose
               sudo /usr/local/bin/docker-compose up -d
               
               EOF
}


