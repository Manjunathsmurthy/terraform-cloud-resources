# Cloud Infrastructure Penetration Testing Suite

Comprehensive Python-based penetration testing framework for AWS, Azure, and GCP cloud infrastructure security assessments.

## Overview

This module provides automated security testing and vulnerability scanning capabilities for multi-cloud deployments. It identifies common misconfigurations, compliance violations, and security risks across major cloud providers.

## Features

### AWS Testing
- **S3 Bucket Security**: Encryption validation, versioning checks, public access block verification
- **IAM Security**: MFA enablement verification, user access audits
- **EC2 Security Groups**: Unrestricted access detection (0.0.0.0/0), rule analysis
- **Multi-profile support**: Test across different AWS accounts

### Azure Testing
- **Storage Account Security**: Encryption and access controls
- **Identity & Access Management**: RBAC verification
- **Network Security**: NSG and firewall rule validation

### GCP Testing
- **Cloud Storage Bucket Security**: Access control and encryption
- **IAM Policies**: Permission verification
- **Network Security**: Firewall and VPC configurations

## Requirements

```bash
pip install -r requirements.txt
```

### Prerequisites
- Python 3.7+
- AWS CLI configured (for AWS tests)
- Azure CLI installed (for Azure tests)
- gcloud CLI configured (for GCP tests)
- Appropriate IAM permissions for scanning resources

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Manjunathsmurthy/terraform-cloud-resources.git
cd terraform-cloud-resources/security-testing
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Basic AWS Penetration Test
```bash
python cloud_pentest.py --cloud aws --verbose
```

### Test Specific AWS Profile
```bash
python cloud_pentest.py --cloud aws --aws-profile production --verbose
```

### Multi-Cloud Assessment
```bash
python cloud_pentest.py --cloud all --aws-profile default --azure-subscription <subscription-id> --gcp-project <project-id>
```

### JSON Output for Integration
```bash
python cloud_pentest.py --cloud aws --output json > pentest_report.json
```

## Command-line Options

```
--cloud {aws,azure,gcp,all}     Cloud provider to test (default: all)
--aws-profile PROFILE           AWS profile to use (default: default)
--azure-subscription SUBID      Azure subscription ID
--gcp-project PROJECT           GCP project ID
--output {json,text}            Output format (default: json)
--verbose, -v                   Enable verbose logging
```

## Output Report

The tool generates comprehensive reports with:
- **Summary**: Total findings, critical/high/medium/low severity counts
- **Findings**: Detailed vulnerabilities with:
  - Severity level (CRITICAL, HIGH, MEDIUM, LOW)
  - Category (S3, IAM, EC2, Storage, etc.)
  - Issue description
  - Remediation guidance
- **Passed Checks**: Security controls that passed validation

## Example Report

```json
{
  "summary": {
    "total_findings": 5,
    "total_passed": 12,
    "critical": 1,
    "high": 2,
    "medium": 2,
    "low": 0
  },
  "findings": [
    {
      "severity": "CRITICAL",
      "category": "S3",
      "issue": "S3 bucket 'data-prod' does not have public access block",
      "remediation": "Enable 'Block all public access' settings"
    }
  ],
  "passed_checks": [
    "S3 bucket 'config-bucket' has encryption enabled",
    "IAM user 'admin' has MFA enabled"
  ]
}
```

## Security Considerations

⚠️ **Important**: This tool performs security assessments on your infrastructure. Ensure you have:

1. **Proper Authorization**: Only run this on infrastructure you own or have explicit permission to test
2. **Appropriate Credentials**: Use IAM roles with minimal required permissions
3. **Audit Logging**: Enable CloudTrail/audit logging to track scan activities
4. **Non-Destructive**: This tool performs read-only assessments (no modifications to resources)

## IAM Permissions Required

### AWS Minimum Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetBucketEncryption",
        "s3:GetBucketVersioning",
        "s3:GetPublicAccessBlock",
        "iam:ListUsers",
        "iam:ListMFADevices",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

## Best Practices

1. **Regular Scans**: Schedule weekly or monthly security assessments
2. **Baseline Tracking**: Compare reports over time to track improvements
3. **Remediation**: Address CRITICAL and HIGH severity findings immediately
4. **Integration**: Integrate into CI/CD pipelines for continuous security monitoring
5. **Access Control**: Run from secure, authorized infrastructure only

## Extending the Framework

Add custom checks by extending the base scanner class:

```python
class CustomPentest(CloudPentestScanner):
    def test_custom_security(self):
        # Your custom security test
        pass
```

## Troubleshooting

### AWS CLI Not Found
```bash
pip install awscli
aws configure
```

### Permission Denied Errors
Ensure the IAM user/role has required permissions and credentials are configured correctly:
```bash
aws sts get-caller-identity
```

### No Buckets Found
Verify AWS CLI is configured and authenticated:
```bash
aws s3api list-buckets
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

This project is part of terraform-cloud-resources and follows the same license.

## Disclaimer

This tool is provided for authorized security testing only. Unauthorized access to computer systems is illegal. Always ensure you have explicit permission before conducting security assessments.

## Support & Resources

- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [Azure Security Baseline](https://learn.microsoft.com/en-us/security/benchmark/azure/)
- [GCP Security Best Practices](https://cloud.google.com/docs/security/best-practices)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
