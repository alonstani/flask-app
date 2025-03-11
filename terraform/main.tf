# Define the Azure provider
provider "azurerm" {
  features {}

  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

# Define the AWS provider
provider "aws" {
  region = "us-east-1"  # Choose the region you want
}

resource "random_id" "sg_suffix" {
  byte_length = 4
}

# AWS EC2 Instance resource
resource "aws_instance" "web" {
  ami           = "ami-04e8b3e527208c8cf"  # Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  key_name      = "inyouk-key"  # Ensure you have a key pair for SSH access
  security_groups = ["as_instance-sg"]  # Replace with your existing security group

  # User data to install necessary packages
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y git
              git clone https://github.com/OmriFialkov/flask-catexer-app-actions.git /home/ec2-user/flask-app
              sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
              sudo curl -o /etc/yum.repos.d/azure-cli.repo https://packages.microsoft.com/config/rhel/8/prod.repo
              sudo yum install -y azure-cli
              AZURE_CLIENT_ID="${var.azure_client_id}"
              AZURE_TENANT_ID="${var.azure_tenant_id}"
              AZURE_CLIENT_SECRET="${var.azure_client_secret}"
              su - ec2-user -c "               
              az login --service-principal \
                  --username $AZURE_CLIENT_ID \
                  --password $AZURE_CLIENT_SECRET \
                  --tenant $AZURE_TENANT_ID
              "
              echo 'az login succeeded!' > /tmp/azlogin.log
              EOF

  # Provisioner to run SSH connection
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.ssh_private_key)  # Reference the path to your private key
    host        = aws_instance.web.public_ip  # EC2 public IP
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/azlogin.log ]; do echo 'waiting for az login to succeed..'; sleep 5; done",
      "echo 'now connecting to azure cluster!'",
      "az aks get-credentials --resource-group inyouk --name my-cluster",  # Adjust with your resource group and AKS name

      # Download kubectl
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "if [ -f ./kubectl ]; then chmod +x kubectl && sudo mv kubectl /usr/local/bin/; else echo 'kubectl download failed'; exit 1; fi",

      # Change directory to the app folder
      "if [ -d /home/ec2-user/flask-app ]; then cd /home/ec2-user/flask-app; else echo 'Directory /home/ec2-user/flask-app not found'; exit 1; fi",

      # Apply Kubernetes configurations
      "echo 'now applying k8s config files!'",
      "kubectl apply -f flask-deployment.yaml
       kubectl apply -f mysql-deploy.yaml
    ]
  }
}

# Output the public IP of the EC2 instance
output "instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}
