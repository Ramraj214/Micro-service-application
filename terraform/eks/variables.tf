variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default = "Micro-service"
}

variable "eks_version" {
  description = "Kubernetes version for EKS Cluster"
  type        = string
  default     = "1.31"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "worker_node_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.xlarge"
}

variable "ami_id" {
  default = "ami-0fd05997b4dff7aac" # Amazon Linux 2023
}

variable "worker_node_disk_size" {
  description = "Disk size for worker nodes in GB"
  type        = number
  default     = 50
}

variable "ssh_cidr_block" {
  description = "CIDR block for SSH access"
  type        = string
  default     = "0.0.0.0/0" # Change this to your IP for security
}

# variable "ssh_key_name" {
#   description = "SSH Key Name for EC2 instances"
#   type        = string
#   default     = "WorkerNodeKey"
# }

