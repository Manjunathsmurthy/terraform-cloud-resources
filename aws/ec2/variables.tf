# AWS EC2 Variables

variable "aws_region" {
  description = "AWS region for EC2 instance"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m5.large"], var.instance_type)
    error_message = "Instance type must be one of the allowed types."
  }
}

variable "instance_name" {
  description = "Name tag for EC2 instance"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  type        = string
}

variable "public_key" {
  description = "Public key for the key pair"
  type        = string
  sensitive   = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
