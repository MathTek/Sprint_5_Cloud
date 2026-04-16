# ========================================
# STAGING Environment Configuration
# ========================================

resource "aws_vpc" "staging" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.staging_tags,
    { Name = "staging-vpc" }
  )
}

resource "aws_subnet" "staging_public" {
  vpc_id                  = aws_vpc.staging.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"
  tags = merge(
    local.staging_tags,
    { Name = "staging-public-subnet" }
  )
}

resource "aws_subnet" "staging_private" {
  vpc_id            = aws_vpc.staging.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-west-3a"
  tags = merge(
    local.staging_tags,
    { Name = "staging-private-subnet" }
  )
}

resource "aws_internet_gateway" "staging" {
  vpc_id = aws_vpc.staging.id
  tags = merge(
    local.staging_tags,
    { Name = "staging-igw" }
  )
}

resource "aws_route_table" "staging_public" {
  vpc_id = aws_vpc.staging.id
  tags = merge(
    local.staging_tags,
    { Name = "staging-public-rt" }
  )
}

resource "aws_route" "staging_internet_access" {
  route_table_id         = aws_route_table.staging_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.staging.id
}

resource "aws_route_table_association" "staging_public" {
  subnet_id      = aws_subnet.staging_public.id
  route_table_id = aws_route_table.staging_public.id
}

resource "aws_route_table" "staging_private" {
  vpc_id = aws_vpc.staging.id
  tags = merge(
    local.staging_tags,
    { Name = "staging-private-rt" }
  )
}

resource "aws_route_table_association" "staging_private" {
  subnet_id      = aws_subnet.staging_private.id
  route_table_id = aws_route_table.staging_private.id
}

# ========================================
# STAGING Security Groups
# ========================================

resource "aws_security_group" "staging_ec2_sg" {
  name        = "staging-ec2-sg"
  description = "Enable only entrance HTTPS traffic"
  vpc_id      = aws_vpc.staging.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.staging_tags,
    { Name = "staging-ec2-sg" }
  )
}

resource "aws_security_group" "staging_dynamodb_sg" {
  name        = "staging-dynamodb-sg"
  description = "Allow access to DynamoDB from VPC"
  vpc_id      = aws_vpc.staging.id

  ingress {
    description = "Allow DynamoDB access from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.staging.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.staging_tags,
    { Name = "staging-dynamodb-sg" }
  )
}

# ========================================
# STAGING IAM Roles
# ========================================

resource "aws_iam_role" "staging_ec2_role" {
  name = "staging-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.staging_tags,
    { Name = "staging-ec2-role" }
  )
}

# S3 Access Policy for Staging EC2
resource "aws_iam_role_policy" "staging_ec2_s3_policy" {
  name = "staging-ec2-s3-policy"
  role = aws_iam_role.staging_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.staging.arn,
          "${aws_s3_bucket.staging.arn}/*"
        ]
      }
    ]
  })
}

# DynamoDB Access Policy for Staging EC2
resource "aws_iam_role_policy" "staging_ec2_dynamodb_policy" {
  name = "staging-ec2-dynamodb-policy"
  role = aws_iam_role.staging_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.staging.arn
      }
    ]
  })
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "staging_ec2_profile" {
  name = "staging-ec2-profile"
  role = aws_iam_role.staging_ec2_role.name
}

# ========================================
# STAGING Compute
# ========================================

resource "aws_instance" "staging_web" {
  ami                    = "ami-003b4ba25626ade0f"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.staging_public.id
  vpc_security_group_ids = [aws_security_group.staging_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.staging_ec2_profile.name

  tags = merge(
    local.staging_tags,
    { Name = "staging-web" }
  )
}

# ========================================
# STAGING Storage
# ========================================

resource "aws_s3_bucket" "staging" {
  bucket        = "cool-delivery-s3-staging-bucket"
  force_destroy = true

  tags = merge(
    local.staging_tags,
    { Name = "staging-bucket" }
  )
}

resource "aws_s3_bucket_versioning" "staging" {
  bucket = aws_s3_bucket.staging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "staging" {
  bucket = aws_s3_bucket.staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "staging_cloudtrail" {
  bucket = aws_s3_bucket.staging.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.staging.arn,
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:eu-west-3:${data.aws_caller_identity.current.account_id}:trail/staging-cloudtrail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.staging.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control",
            "aws:SourceArn" = "arn:aws:cloudtrail:eu-west-3:${data.aws_caller_identity.current.account_id}:trail/staging-cloudtrail"
          }
        }
      }
    ]
  })
}

# ========================================
# STAGING Database
# ========================================

resource "aws_dynamodb_table" "staging" {
  name           = "staging-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  depends_on     = [aws_vpc_endpoint.staging_s3]

  attribute {
    name = "id"
    type = "S"
  }

  hash_key = "id"

  tags = merge(
    local.staging_tags,
    { Name = "staging-table" }
  )
}

# ========================================
# STAGING VPC Endpoints
# ========================================

resource "aws_vpc_endpoint" "staging_s3" {
  vpc_id            = aws_vpc.staging.id
  service_name      = "com.amazonaws.eu-west-3.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.staging_private.id]

  tags = merge(
    local.staging_tags,
    { Name = "staging-s3-endpoint" }
  )
}

resource "aws_vpc_endpoint_policy" "staging_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.staging_s3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.staging.arn}/*"
      },
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:ListBucket",
        Resource  = aws_s3_bucket.staging.arn
      }
    ]
  })
}

resource "aws_vpc_endpoint" "staging_dynamodb" {
  vpc_id            = aws_vpc.staging.id
  service_name      = "com.amazonaws.eu-west-3.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.staging_private.id]

  tags = merge(
    local.staging_tags,
    { Name = "staging-dynamodb-endpoint" }
  )
}

resource "aws_vpc_endpoint_policy" "staging_dynamodb" {
  vpc_endpoint_id = aws_vpc_endpoint.staging_dynamodb.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.staging.arn
      }
    ]
  })
}

# ========================================
# STAGING Monitoring
# ========================================

resource "aws_cloudtrail" "staging" {
  name                          = "staging-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.staging.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.staging_cloudtrail, aws_iam_role_policy.staging_cloudtrail_logs_policy]

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(
    local.staging_tags,
    { Name = "staging-cloudtrail" }
  )
}

resource "aws_iam_role" "staging_cloudtrail_logs_role" {
  name = "staging-cloudtrail-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.staging_tags,
    { Name = "staging-cloudtrail-logs-role" }
  )
}

resource "aws_iam_role_policy" "staging_cloudtrail_logs_policy" {
  name = "staging-cloudtrail-logs-policy"
  role = aws_iam_role.staging_cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:eu-west-3:${data.aws_caller_identity.current.account_id}:log-group:/aws/cloudtrail/staging:*"
      }
    ]
  })
}


