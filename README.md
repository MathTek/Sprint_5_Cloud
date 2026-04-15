## CI/CD Pipeline

This project uses GitHub Actions to enforce security:

- Gitleaks → detects secrets
- Checkov → scans Terraform misconfigurations
- Trivy → detects vulnerabilities

The pipeline fails automatically if any issue is detected.