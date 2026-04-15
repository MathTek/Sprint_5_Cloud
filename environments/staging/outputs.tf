output "staging_vpc_id" {
  description = "ID of the Staging VPC"
  value       = aws_vpc.staging.id
}

output "staging_subnet_public_id" {
  description = "ID of the Staging public subnet"
  value       = aws_subnet.staging_public.id
}

output "staging_subnet_private_id" {
  description = "ID of the Staging private subnet"
  value       = aws_subnet.staging_private.id
}

output "staging_ec2_instance_id" {
  description = "ID of the Staging EC2 instance"
  value       = aws_instance.staging_web.id
}

output "staging_ec2_private_ip" {
  description = "Private IP of the Staging EC2 instance"
  value       = aws_instance.staging_web.private_ip
}

output "staging_ec2_public_ip" {
  description = "Public IP of the Staging EC2 instance"
  value       = aws_instance.staging_web.public_ip
}

output "staging_s3_bucket_name" {
  description = "Name of the Staging S3 bucket"
  value       = aws_s3_bucket.staging.id
}

output "staging_s3_bucket_arn" {
  description = "ARN of the Staging S3 bucket"
  value       = aws_s3_bucket.staging.arn
}

output "staging_vpc_endpoint_s3_id" {
  description = "ID of the Staging VPC Endpoint for S3"
  value       = aws_vpc_endpoint.staging_s3.id
}

output "staging_cloudtrail_name" {
  description = "Name of the Staging CloudTrail"
  value       = aws_cloudtrail.staging.name
}

output "staging_dynamodb_table_name" {
  description = "Name of the Staging DynamoDB table"
  value       = aws_dynamodb_table.staging.name
}
