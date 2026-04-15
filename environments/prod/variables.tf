variable "rds_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "La région AWS à utiliser"
  type        = string
  default     = "eu-west-3"
}
