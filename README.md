## CI/CD Pipeline

This project uses GitHub Actions to enforce security and validate Terraform configurations across multiple environments (dev, staging, prod):

- Gitleaks → detects secrets
- Checkov → scans Terraform misconfigurations for each environment
- Trivy → detects vulnerabilities
- Terraform fmt → checks code formatting
- Terraform validate → validates configuration syntax
- Terraform plan → previews changes for each environment

The pipeline fails automatically if any issue is detected.