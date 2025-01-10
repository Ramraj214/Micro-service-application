# VPC Module
module "vpc" {
  source = "../vpc"
}

# Security Groups
resource "aws_security_group" "control_plane_security_group" {
  name        = "control_plane_security_group"
  description = "Security group for EKS control plane"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_node_security_group.id]
  }

  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_node_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "worker_node_security_group" {
  name        = "worker_node_security_group"
  description = "Security group for worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr_block]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IP
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr_block]
  }

  ingress {
    from_port   = 30002
    to_port     = 30005
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust to limit traffic as needed
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Node Exporter traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_control_plane_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids         = [module.vpc.public_subnet1_id, module.vpc.public_subnet2_id]
    security_group_ids = [aws_security_group.control_plane_security_group.id]
  }

  depends_on = [aws_iam_role.eks_control_plane_role]
}

resource "aws_launch_template" "worker_node_launch_template" {
  name = "worker-node-launch-template"

  vpc_security_group_ids = [
    aws_security_group.worker_node_security_group.id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.worker_node_disk_size # Disk size specified here
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }
}

# EKS Node Group without Launch Template
resource "aws_eks_node_group" "worker_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-worker-nodes"
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = [module.vpc.public_subnet1_id, module.vpc.public_subnet2_id]

  launch_template {
    name    = aws_launch_template.worker_node_launch_template.name
    version = "$Latest"
  }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  capacity_type = "ON_DEMAND"
  ami_type      = "AL2_x86_64"

  labels = {
    role = "worker"
  }

  instance_types = [var.worker_node_instance_type]
}

# IAM Roles and Policies
resource "aws_iam_instance_profile" "worker_node_instance_profile" {
  name = "worker_node_instance_profile"
  role = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role" "eks_control_plane_role" {
  name = "eks_control_plane_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "worker_node_role" {
  name = "worker_node_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_control_plane_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_control_plane_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_control_plane_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_control_plane_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
