# AWS Landing Zone - Enterprise Foundation
# Implements AWS best practices for multi-account organization

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ===== VPC & NETWORKING =====
# Production VPC
resource "aws_vpc" "production" {
  cidr_block           = var.prod_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.organization}-prod-vpc"
    Environment = "production"
  }
}

# Production Public Subnets
resource "aws_subnet" "prod_public" {
  count             = 3
  vpc_id            = aws_vpc.production.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.prod_vpc_cidr, 4, count.index)

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.organization}-prod-public-${count.index + 1}"
  }
}

# Production Private Subnets
resource "aws_subnet" "prod_private" {
  count             = 3
  vpc_id            = aws_vpc.production.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.prod_vpc_cidr, 4, count.index + 3)

  tags = {
    Name = "${var.organization}-prod-private-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name = "${var.organization}-prod-igw"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"

  tags = {
    Name = "${var.organization}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.prod]
}

# NAT Gateways
resource "aws_nat_gateway" "prod" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.prod_public[count.index].id

  tags = {
    Name = "${var.organization}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.prod]
}

# ===== SECURITY =====
# CloudTrail S3 Bucket
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.organization}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.organization}-cloudtrail"
  }
}

# Enable versioning and encryption for CloudTrail bucket
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail
resource "aws_cloudtrail" "organization" {
  name                          = "${var.organization}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ===== MONITORING =====
# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.organization}"
  retention_in_days = 30

  tags = {
    Name = "${var.organization}-vpc-flow-logs"
  }
}

# VPC Flow Logs IAM Role
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.organization}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.organization}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.production.id

  tags = {
    Name = "${var.organization}-vpc-flow-logs"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}
