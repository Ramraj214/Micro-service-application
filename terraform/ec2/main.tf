resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg"
  description = "Allow required application ports"
  vpc_id      = "vpc-08d03b361ee4e6489" # Correct VPC reference

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access (Optional if serving any web apps over HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress Rule (Allow all outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = "subnet-097e6e4533f3fa63e"
  vpc_security_group_ids = [aws_security_group.web_sg.id] # Security group IDs

  tags = {
    Name = "WebServer1"
  }

  # EBS Volume Configuration
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Optional: Additional Block Device (if you want more volumes)
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  provisioner "remote-exec" {
    inline = [
      # Update and install necessary tools
      "sudo yum update -y",
      "sudo amazon-linux-extras enable ansible2",
      "sudo yum install -y ansible",

      # Install Java 17 Amazon Corretto
      "sudo amazon-linux-extras enable corretto17",
      "sudo yum install -y java-17-amazon-corretto-devel",

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
  }
}
