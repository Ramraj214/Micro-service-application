# ------------------------------------------
# Security Group for Jenkins Master
# ------------------------------------------
resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg"
  description = "Allow required application ports"
  vpc_id      = "vpc-08d03b361ee4e6489"

  # SSH Access (Allow all IPs)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access (Allow all IPs)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins UI (Allow all IPs)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Jenkins Agent Communication (Master <--> Slaves) (Allow all IPs)
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "JenkinsMasterSg"
  }
}

# ------------------------------------------
# Security Group for Jenkins Slaves
# ------------------------------------------
resource "aws_security_group" "slave_sg" {
  name_prefix = "slave-sg"
  description = "Allow required application ports"
  vpc_id      = "vpc-08d03b361ee4e6489"

  # SSH Access (Allow all IPs)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access (Allow all IPs)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube (Allow all IPs)
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkinsSlaveSg"
  }
}

# ------------------------------------------
# Jenkins Master Instance
# ------------------------------------------
resource "aws_instance" "jenkins_master" {
  ami                    = var.ami_id # Amazon Linux 2023 AMI
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = "subnet-097e6e4533f3fa63e"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = {
    Name = "Jenkins-Master"
  }

  # Root Volume
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  provisioner "file" {
    source      = "C:/Users/ramra/Downloads/MyKey.pem"
    destination = "/home/ec2-user/MyKey.pem"
  }

  # Install Jenkins, Java, Ansible, and other dependencies
  provisioner "remote-exec" {
    inline = [
      "sleep 60", # Ensure instance is fully booted
      "sudo yum update -y",
      "chmod 700 /home/ec2-user/MyKey.pem", # Make the file executable (secure permissions)

      # Install Java 17 (OpenJDK)
      "sudo yum install -y java-17-amazon-corretto",

      # Install Ansible
      "sudo yum install -y ansible",

      # Install Python3 and Boto3 for AWS integration
      "sudo yum install -y python3-pip",
      "pip3 install boto3 botocore --user",
      "ansible-galaxy collection install amazon.aws",

      # Import Jenkins GPG key
      "sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key",

      # Add Jenkins repository
      "sudo tee /etc/yum.repos.d/jenkins.repo <<EOF",
      "[jenkins]",
      "name=Jenkins",
      "baseurl=https://pkg.jenkins.io/redhat-stable/",
      "gpgcheck=0",
      "enabled=1",
      "EOF",

      # Clean and update the package cache
      "sudo yum clean all",
      "sudo yum makecache",

      # Install Jenkins
      "sudo yum install -y jenkins",

      # Add Jenkins user to the 'users' group
      "sudo usermod -aG users jenkins",

      # Start and enable Jenkins service
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",

      # Verify Jenkins service status
      "systemctl is-active jenkins || { echo 'Jenkins service is not active'; exit 1; }"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.key_path)
    host        = self.public_ip
    timeout     = "5m"
  }
}

# ------------------------------------------
# Jenkins Slave Nodes (2 Instances)
# ------------------------------------------
resource "aws_instance" "jenkins_slave" {
  count = 2 # Creates two slave instances

  ami                    = var.ami_id # Amazon Linux 2023 AMI
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = "subnet-097e6e4533f3fa63e"
  vpc_security_group_ids = [aws_security_group.slave_sg.id]

  tags = {
    Name = "Jenkins-Slave-${count.index + 1}"
  }

  # Root Volume
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  depends_on = [aws_instance.jenkins_master] # Ensure master is created first

  # Install Java, Git, Docker (For Slave Node)
  provisioner "remote-exec" {
    inline = [
      "set -e",   # Exit immediately if any command fails
      "sleep 60", # Ensure instance is fully booted
      "sudo yum update -y",

      # Install Java 17 (OpenJDK)
      "sudo yum install -y java-17-amazon-corretto",

      # Install Git
      "sudo yum install -y git",

      # Install Docker
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # Add 'ec2-user' to Docker group
      "sudo usermod -aG docker ec2-user",

      # Verify installations
      "java -version",
      "git --version",
      "docker --version"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.key_path)
    host        = self.public_ip
    timeout     = "5m"
  }
}
