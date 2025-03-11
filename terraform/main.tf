variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH private key"
  type        = string
}

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
  ami           = "ami-04b4f1a9cf54c11d0"  # Ubuntu AMI ID for the region, you may need to adjust this if different
  instance_type = "t2.micro"
  key_name      = "inyouk-key"  # Ensure you have a key pair for SSH access
  security_groups = ["as_instance-sg"]  # Replace with your existing security group

  # User data to install necessary packages
  user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo apt update -y
              
              # Install git
              sudo apt install -y git
              
              # Clone the Flask app repository
              git clone https://github.com/OmriFialkov/flask-catexer-app-actions.git /home/ubuntu/flask-app
              
              # Install dependencies for Azure CLI
              sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg
              sudo curl -sL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
              sudo curl -sL https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
              sudo apt update
              sudo apt install -y azure-cli
              
              # Set environment variables for Azure CLI login
              AZURE_CLIENT_ID="${var.azure_client_id}"
              AZURE_TENANT_ID="${var.azure_tenant_id}"
              AZURE_CLIENT_SECRET="${var.azure_client_secret}"
              
              # Login to Azure using the service principal
              su - ubuntu -c "az login --service-principal --username \$AZURE_CLIENT_ID --password \$AZURE_CLIENT_SECRET --tenant \$AZURE_TENANT_ID"
              
              # Create a success log after AZ login
              echo 'az login succeeded!' > /tmp/azlogin.log
EOF

  # Provisioner to run SSH connection
  connection {
    type        = "ssh"
    user        = "ubuntu"  # Default user for Ubuntu AMIs
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
      "if [ -d /home/ubuntu/flask-app ]; then cd /home/ubuntu/flask-app; else echo 'Directory /home/ubuntu/flask-app not found'; exit 1; fi",

      # Apply Kubernetes configurations
      "echo 'now applying k8s config files!'",
      "kubectl apply -f flask-deployment.yaml",
      "kubectl apply -f mysql-deploy.yaml"
    ]
  }
}

# Output the public IP of the EC2 instance
output "instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}
