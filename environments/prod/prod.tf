# ========================================
# PRODUCTION Environment Configuration
# ========================================

resource "aws_vpc" "prod" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.prod_tags,
    { Name = "prod-vpc" }
  )
}

resource "aws_subnet" "prod_public" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "10.2.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-3a"
  tags = merge(
    local.prod_tags,
    { Name = "prod-public-subnet" }
  )
}

resource "aws_subnet" "prod_public_b" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "10.2.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-3b"
  tags = merge(
    local.prod_tags,
    { Name = "prod-public-subnet-b" }
  )
}

# ========================================
# PROD Private Subnets (for RDS)
# ========================================

resource "aws_subnet" "prod_private" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "eu-west-3a"
  tags = merge(
    local.prod_tags,
    { Name = "prod-private-subnet" }
  )
}

resource "aws_subnet" "prod_private_b" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.2.4.0/24"
  availability_zone = "eu-west-3b"
  tags = merge(
    local.prod_tags,
    { Name = "prod-private-subnet-b" }
  )
}

# ========================================
# PROD Internet Gateway
# ========================================

resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id
  tags = merge(
    local.prod_tags,
    { Name = "prod-igw" }
  )
}

# ========================================
# PROD Route Tables
# ========================================

resource "aws_route_table" "prod_public" {
  vpc_id = aws_vpc.prod.id
  tags = merge(
    local.prod_tags,
    { Name = "prod-public-rt" }
  )
}

resource "aws_route" "prod_internet_access" {
  route_table_id         = aws_route_table.prod_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.prod.id
}

resource "aws_route_table_association" "prod_public" {
  subnet_id      = aws_subnet.prod_public.id
  route_table_id = aws_route_table.prod_public.id
}

resource "aws_route_table_association" "prod_public_b" {
  subnet_id      = aws_subnet.prod_public_b.id
  route_table_id = aws_route_table.prod_public.id
}

resource "aws_route_table" "prod_private" {
  vpc_id = aws_vpc.prod.id
  tags = merge(
    local.prod_tags,
    { Name = "prod-private-rt" }
  )
}

resource "aws_route_table_association" "prod_private" {
  subnet_id      = aws_subnet.prod_private.id
  route_table_id = aws_route_table.prod_private.id
}

resource "aws_route_table_association" "prod_private_b" {
  subnet_id      = aws_subnet.prod_private_b.id
  route_table_id = aws_route_table.prod_private.id
}

# ========================================
# PROD Security Groups
# ========================================

resource "aws_security_group" "prod_ec2_sg" {
  name        = "prod-ec2-sg"
  description = "Enable only HTTPS traffic"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-ec2-sg" }
  )
}

resource "aws_security_group" "prod_rds_sg" {
  name        = "prod-rds-sg"
  description = "Enable PostgreSQL from EC2 only"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description     = "PostgreSQL from EC2 only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_ec2_sg.id]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-sg" }
  )
}

resource "aws_security_group" "prod_vpc_endpoint_sg" {
  name        = "prod-vpc-endpoint-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "HTTPS for VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.prod.cidr_block]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-vpc-endpoint-sg" }
  )
}

# ========================================
# PROD Compute
# ========================================

resource "aws_instance" "prod_web" {
  ami                    = "ami-003b4ba25626ade0f"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.prod_public.id
  vpc_security_group_ids = [aws_security_group.prod_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.prod_ec2_profile.name
  ebs_optimized          = true
  monitoring             = true

  tags = merge(
    local.prod_tags,
    { Name = "prod-web" }
  )
}

# ========================================
# PROD Database
# ========================================

resource "aws_db_subnet_group" "prod" {
  name       = "prod-db-subnet-group"
  subnet_ids = [aws_subnet.prod_private.id, aws_subnet.prod_private_b.id]

  tags = merge(
    local.prod_tags,
    { Name = "prod-db-subnet-group" }
  )
}

resource "aws_db_instance" "prod_postgres" {
  identifier              = "prod-postgres"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "postgres"
  password                = var.rds_password
  db_subnet_group_name    = aws_db_subnet_group.prod.name
  vpc_security_group_ids  = [aws_security_group.prod_rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.prod_rds.arn
  backup_retention_period = 1
  apply_immediately       = true

  tags = merge(
    local.prod_tags,
    { Name = "prod-postgres" }
  )
}

# ========================================
# PROD KMS Keys
# ========================================

resource "aws_kms_key" "prod_rds" {
  description         = "KMS key for RDS encryption (Prod)"
  enable_key_rotation = true
}

resource "aws_kms_key_policy" "prod_rds" {
  key_id = aws_kms_key.prod_rds.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow RDS to use the key",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "prod_s3" {
  description         = "KMS key for S3 bucket encryption (Prod)"
  enable_key_rotation = true
}

resource "aws_kms_key_policy" "prod_s3" {
  key_id = aws_kms_key.prod_s3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:DecryptDataKey"
        ],
        Resource = "*",
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      },
      {
        Sid    = "Allow S3 bucket operations",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

# ========================================
# PROD Storage
# ========================================

resource "aws_s3_bucket" "prod" {
  bucket        = "cool-delivery-prod-s3-bucket"
  force_destroy = true

  tags = merge(
    local.prod_tags,
    { Name = "prod-bucket" }
  )
}

resource "aws_s3_bucket_versioning" "prod" {
  bucket = aws_s3_bucket.prod.id

  versioning_configuration {
    status     = "Enabled"
    
  }
}

resource "aws_s3_bucket_public_access_block" "prod" {
  bucket = aws_s3_bucket.prod.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod" {
  bucket = aws_s3_bucket.prod.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.prod_s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "prod_main" {
  bucket = aws_s3_bucket.prod.id

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
        Resource = aws_s3_bucket.prod.arn
      },
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.prod.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowProdEC2Access",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.prod_ec2_role.arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.prod.arn,
          "${aws_s3_bucket.prod.arn}/*"
        ]
      }
    ]
  })
}

# ========================================
# PROD VPC Endpoints
# ========================================

resource "aws_vpc_endpoint" "prod_s3" {
  vpc_id            = aws_vpc.prod.id
  service_name      = "com.amazonaws.eu-west-3.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.prod_private.id]

  tags = merge(
    local.prod_tags,
    { Name = "prod-s3-endpoint" }
  )
}

resource "aws_vpc_endpoint_policy" "prod_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.prod_s3.id

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
        Resource = "${aws_s3_bucket.prod.arn}/*"
      },
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:ListBucket",
        Resource  = aws_s3_bucket.prod.arn
      }
    ]
  })
}

resource "aws_vpc_endpoint" "prod_kms" {
  vpc_id              = aws_vpc.prod.id
  service_name        = "com.amazonaws.eu-west-3.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.prod_private.id, aws_subnet.prod_private_b.id]
  security_group_ids  = [aws_security_group.prod_vpc_endpoint_sg.id]

  tags = merge(
    local.prod_tags,
    { Name = "prod-kms-endpoint" }
  )
}

# ========================================
# PROD IAM Roles & Policies
# ========================================

resource "aws_iam_role" "prod_ec2_role" {
  name = "prod-ec2-role"

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
}

resource "aws_iam_role_policy" "prod_ec2_s3" {
  name = "prod-ec2-s3-policy"
  role = aws_iam_role.prod_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.prod.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "prod_ec2_kms" {
  name = "prod-ec2-kms-policy"
  role = aws_iam_role.prod_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.prod_s3.arn,
          aws_kms_key.prod_rds.arn
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "prod_ec2_profile" {
  name = "prod-ec2-profile"
  role = aws_iam_role.prod_ec2_role.name
}

resource "aws_iam_role" "prod_cloudtrail_logs_role" {
  name = "prod-cloudtrail-logs-role"

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
    local.prod_tags,
    { Name = "prod-cloudtrail-logs-role" }
  )
}

resource "aws_iam_role_policy" "prod_cloudtrail_logs_policy" {
  name = "prod-cloudtrail-logs-policy"
  role = aws_iam_role.prod_cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:eu-west-3:${data.aws_caller_identity.current.account_id}:log-group:/aws/cloudtrail/prod:*"
      }
    ]
  })
}

resource "aws_cloudtrail" "prod" {
  name                          = "prod-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.prod.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.prod_s3.arn
  depends_on                    = [aws_s3_bucket_policy.prod_main, aws_iam_role_policy.prod_cloudtrail_logs_policy]
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.prod_cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.prod_cloudtrail_logs_role.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-cloudtrail" }
  )
}



resource "aws_cloudwatch_metric_alarm" "prod_rds_cpu" {
  alarm_name          = "prod-rds-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when Prod RDS CPU utilization is >= 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.prod_postgres.identifier
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-cpu-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_rds_storage" {
  alarm_name          = "prod-rds-free-storage-space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648"
  alarm_description   = "Alert when Prod RDS free storage space is <= 2GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.prod_postgres.identifier
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-storage-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_rds_connections" {
  alarm_name          = "prod-rds-database-connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when Prod RDS database connections is >= 80"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.prod_postgres.identifier
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-connections-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_rds_replica_lag" {
  alarm_name          = "prod-rds-replication-lag"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "10"
  alarm_description   = "Alert when Prod RDS replication lag is >= 10 seconds"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.prod_postgres.identifier
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-replica-lag-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_rds_read_latency" {
  alarm_name          = "prod-rds-read-latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Alert when Prod RDS read latency is >= 5ms"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.prod_postgres.identifier
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-read-latency-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_rds_write_latency" {
  alarm_name          = "prod-rds-write-latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Alert when Prod RDS write latency is >= 5ms"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.prod_postgres.identifier
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-rds-write-latency-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_ec2_cpu" {
  alarm_name          = "prod-ec2-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Alert when Prod EC2 CPU utilization is >= 75%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.prod_web.id
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-ec2-cpu-alarm" }
  )
}

resource "aws_cloudwatch_metric_alarm" "prod_ec2_status_check" {
  alarm_name          = "prod-ec2-status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when Prod EC2 status check fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.prod_web.id
  }

  tags = merge(
    local.prod_tags,
    { Name = "prod-ec2-status-check-alarm" }
  )
}

resource "aws_cloudwatch_log_group" "prod_cloudtrail_logs" {
  name              = "/aws/cloudtrail/prod"
  retention_in_days = 7

  tags = merge(
    local.prod_tags,
    { Name = "prod-cloudtrail-logs" }
  )
}

resource "aws_cloudwatch_log_stream" "prod_cloudtrail_stream" {
  name           = "prod-cloudtrail-stream"
  log_group_name = aws_cloudwatch_log_group.prod_cloudtrail_logs.name
}

resource "aws_cloudwatch_metric_alarm" "prod_suspicious_api_calls" {
  alarm_name          = "prod-suspicious-api-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SuspiciousAPICallsCount"
  namespace           = "CloudTrailMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when there are suspicious API calls (UnauthorizedOperation, AccessDenied)"
  treat_missing_data  = "notBreaching"

  tags = merge(
    local.prod_tags,
    { Name = "prod-suspicious-api-calls-alarm" }
  )
}

resource "aws_cloudwatch_log_metric_filter" "prod_suspicious_api_calls" {
  name           = "SuspiciousAPICallsMetricFilter"
  log_group_name = aws_cloudwatch_log_group.prod_cloudtrail_logs.name
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "SuspiciousAPICallsCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}
