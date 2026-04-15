output "prod_vpc_id" {
  description = "ID of the Prod VPC"
  value       = aws_vpc.prod.id
}

output "prod_subnet_public_id" {
  description = "ID of the Prod public subnet (AZ a)"
  value       = aws_subnet.prod_public.id
}

output "prod_subnet_public_b_id" {
  description = "ID of the Prod public subnet (AZ b)"
  value       = aws_subnet.prod_public_b.id
}

output "prod_subnet_private_id" {
  description = "ID of the Prod private subnet (AZ a)"
  value       = aws_subnet.prod_private.id
}

output "prod_subnet_private_b_id" {
  description = "ID of the Prod private subnet (AZ b)"
  value       = aws_subnet.prod_private_b.id
}

output "prod_ec2_instance_id" {
  description = "ID of the Prod EC2 instance"
  value       = aws_instance.prod_web.id
}

output "prod_ec2_private_ip" {
  description = "Private IP of the Prod EC2 instance"
  value       = aws_instance.prod_web.private_ip
}

output "prod_ec2_public_ip" {
  description = "Public IP of the Prod EC2 instance"
  value       = aws_instance.prod_web.public_ip
}

output "prod_s3_bucket_name" {
  description = "Name of the Prod S3 bucket"
  value       = aws_s3_bucket.prod.id
}

output "prod_s3_bucket_arn" {
  description = "ARN of the Prod S3 bucket"
  value       = aws_s3_bucket.prod.arn
}

output "prod_kms_s3_key_id" {
  description = "ID of the KMS key for Prod S3 encryption"
  value       = aws_kms_key.prod_s3.id
}

output "prod_kms_rds_key_id" {
  description = "ID of the KMS key for Prod RDS encryption"
  value       = aws_kms_key.prod_rds.id
}

output "prod_rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.prod_postgres.endpoint
}

output "prod_rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.prod_postgres.identifier
}

output "prod_vpc_endpoint_s3_id" {
  description = "ID of the Prod VPC Endpoint for S3"
  value       = aws_vpc_endpoint.prod_s3.id
}

output "prod_vpc_endpoint_kms_id" {
  description = "ID of the Prod VPC Endpoint for KMS"
  value       = aws_vpc_endpoint.prod_kms.id
}

output "prod_cloudtrail_name" {
  description = "Name of the Prod CloudTrail"
  value       = aws_cloudtrail.prod.name
}

output "prod_ec2_iam_role_arn" {
  description = "ARN of the Prod EC2 IAM Role"
  value       = aws_iam_role.prod_ec2_role.arn
}

output "prod_cloudwatch_alarm_rds_cpu_id" {
  description = "ID of the RDS CPU Utilization CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.prod_rds_cpu.alarm_name
}

output "prod_cloudwatch_alarm_rds_storage_id" {
  description = "ID of the RDS Free Storage CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.prod_rds_storage.alarm_name
}
