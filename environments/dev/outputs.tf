output "dev_vpc_id" {
  description = "ID of the Dev VPC"
  value       = aws_vpc.dev.id
}

output "dev_subnet_public_id" {
  description = "ID of the Dev public subnet"
  value       = aws_subnet.dev_public.id
}

output "dev_ec2_instance_id" {
  description = "ID of the Dev EC2 instance"
  value       = aws_instance.dev_web.id
}

output "dev_ec2_private_ip" {
  description = "Private IP of the Dev EC2 instance"
  value       = aws_instance.dev_web.private_ip
}

output "dev_ec2_public_ip" {
  description = "Public IP of the Dev EC2 instance"
  value       = aws_instance.dev_web.public_ip
}

output "dev_s3_bucket_name" {
  description = "Name of the Dev S3 bucket"
  value       = aws_s3_bucket.dev.id
}

output "dev_s3_bucket_arn" {
  description = "ARN of the Dev S3 bucket"
  value       = aws_s3_bucket.dev.arn
}

output "dev_cloudtrail_name" {
  description = "Name of the Dev CloudTrail"
  value       = aws_cloudtrail.dev.name
}

output "dev_dynamodb_table_name" {
  description = "Name of the Dev DynamoDB table"
  value       = aws_dynamodb_table.dev.name
}
