# ========================================
# DEV Environment Configuration
# ========================================

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  tags = merge(
    local.dev_tags,
    { Name = "dev-vpc" }
  )
}

resource "aws_subnet" "dev_public" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"
  tags = merge(
    local.dev_tags,
    { Name = "dev-public-subnet" }
  )
}

resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.dev.id
  tags = merge(
    local.dev_tags,
    { Name = "dev-igw" }
  )
}

resource "aws_route_table" "dev_public" {
  vpc_id = aws_vpc.dev.id
  tags = merge(
    local.dev_tags,
    { Name = "dev-public-rt" }
  )
}

resource "aws_route" "dev_internet_access" {
  route_table_id         = aws_route_table.dev_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev.id
}

resource "aws_route_table_association" "dev_public" {
  subnet_id      = aws_subnet.dev_public.id
  route_table_id = aws_route_table.dev_public.id
}

# ========================================
# DEV Security Groups
# ========================================

resource "aws_security_group" "dev_ec2_sg" {
  name        = "dev-ec2-sg"
  description = "Enable only entrance HTTPS traffic"
  vpc_id      = aws_vpc.dev.id

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
    local.dev_tags,
    { Name = "dev-ec2-sg" }
  )
}

# ========================================
# DEV Compute
# ========================================

resource "aws_instance" "dev_web" {
  ami                    = "ami-003b4ba25626ade0f"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.dev_public.id
  vpc_security_group_ids = [aws_security_group.dev_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.dev_ec2_profile.name

  tags = merge(
    local.dev_tags,
    { Name = "dev-web" }
  )
}

# ========================================
# DEV Storage
# ========================================

resource "aws_s3_bucket" "dev" {
  bucket        = "cool-delivery-s3-dev-bucket"
  force_destroy = true

  tags = merge(
    local.dev_tags,
    { Name = "dev-bucket" }
  )
}

resource "aws_s3_bucket_versioning" "dev" {
  bucket = aws_s3_bucket.dev.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket = aws_s3_bucket.dev.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "dev_cloudtrail" {
  bucket = aws_s3_bucket.dev.id

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
        Resource = aws_s3_bucket.dev.arn,
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:eu-west-3:${data.aws_caller_identity.current.account_id}:trail/dev-cloudtrail"
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
        Resource = "${aws_s3_bucket.dev.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control",
            "aws:SourceArn" = "arn:aws:cloudtrail:eu-west-3:${data.aws_caller_identity.current.account_id}:trail/dev-cloudtrail"
          }
        }
      }
    ]
  })
}

# ========================================
# DEV Database
# ========================================

resource "aws_dynamodb_table" "dev" {
  name           = "dev-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }

  hash_key = "id"

  tags = merge(
    local.dev_tags,
    { Name = "dev-table" }
  )
}

# ========================================
# DEV IAM for EC2 → DynamoDB
# ========================================

resource "aws_iam_role" "dev_ec2_role" {
  name = "dev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.dev_tags,
    { Name = "dev-ec2-role" }
  )
}

resource "aws_iam_role_policy" "dev_ec2_dynamodb" {
  name = "dev-ec2-dynamodb-policy"
  role = aws_iam_role.dev_ec2_role.id

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
        Resource = aws_dynamodb_table.dev.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dev_ec2_profile" {
  name = "dev-ec2-profile"
  role = aws_iam_role.dev_ec2_role.name
}

# ========================================
# DEV IAM for CloudTrail
# ========================================

resource "aws_iam_role" "dev_cloudtrail_logs_role" {
  name = "dev-cloudtrail-logs-role"

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
    local.dev_tags,
    { Name = "dev-cloudtrail-logs-role" }
  )
}

resource "aws_iam_role_policy" "dev_cloudtrail_logs_policy" {
  name = "dev-cloudtrail-logs-policy"
  role = aws_iam_role.dev_cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:eu-west-3:${data.aws_caller_identity.current.account_id}:log-group:/aws/cloudtrail/dev:*"
      }
    ]
  })
}

# ========================================
# DEV Monitoring
# ========================================


resource "aws_cloudtrail" "dev" {
  name                          = "dev-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.dev.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.dev_cloudtrail, aws_iam_role_policy.dev_cloudtrail_logs_policy]


  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(
    local.dev_tags,
    { Name = "dev-cloudtrail" }
  )
}
