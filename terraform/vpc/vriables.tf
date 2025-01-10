# Variables for the VPC setup
variable "region" {
  description = "The AWS region to deploy in"
  default     = "ap-south-1"  # Change this to your desired region (e.g., us-east-1)
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet1_cidr" {
  description = "The CIDR block for the first public subnet"
  default     = "10.0.1.0/24"
}

variable "public_subnet2_cidr" {
  description = "The CIDR block for the second public subnet"
  default     = "10.0.2.0/24"
}

variable "public_subnet3_cidr" {
  description = "The CIDR block for the third public subnet"
  default     = "10.0.3.0/24"
}

variable "public_subnet4_cidr" {
  description = "The CIDR block for the fourth public subnet"
  default     = "10.0.4.0/24"
}

variable "private_subnet1_cidr" {
  description = "The CIDR block for the first private subnet"
  default     = "10.0.5.0/24"
}

variable "private_subnet2_cidr" {
  description = "The CIDR block for the second private subnet"
  default     = "10.0.6.0/24"
}

# Availability zones for public and private subnets
variable "availability_zone1" {
  description = "The availability zone for public subnet 1"
  default     = "ap-south-1a"  # Change if needed for other regions
}

variable "availability_zone2" {
  description = "The availability zone for public subnet 2"
  default     = "ap-south-1b"  # Change if needed for other regions
}

variable "availability_zone3" {
  description = "The availability zone for public subnet 3"
  default     = "ap-south-1c"  # Change if needed for other regions
}

variable "availability_zone4" {
  description = "The availability zone for public subnet 4"
  default     = "ap-south-1d"  # Change if needed for other regions
}

variable "private_availability_zone1" {
  description = "The availability zone for private subnet 1"
  default     = "ap-south-1a"  # Change if needed for other regions
}

variable "private_availability_zone2" {
  description = "The availability zone for private subnet 2"
  default     = "ap-south-1b"  # Change if needed for other regions
}