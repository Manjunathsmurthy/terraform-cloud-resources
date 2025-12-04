# Ansible SRE Playbooks Collection

**Purpose**: Enterprise-grade Ansible playbooks for Site Reliability Engineers and Cloud Architects to automate infrastructure operations, security, monitoring, and compliance across Linux systems.

## Overview

This collection provides production-ready Ansible playbooks designed for:
- System Administration & Automation
- Security Hardening & Compliance (CIS Benchmarks)
- Monitoring & Observability Setup
- Kubernetes Operations
- Database Management & Backups
- Cloud Infrastructure Operations

## Playbooks

### 1. **system-admin.yml**
**Purpose**: Core Linux system administration and maintenance

**Tasks**:
- User management (create system users, configure sudoers)
- Package management (updates, essential packages)
- Time synchronization (NTP/Chrony configuration)
- System limits & file descriptors
- Kernel parameter tuning (sysctl)
- Service management (enable/start critical services)
- Network configuration (IP forwarding)
- Security baseline (disable unnecessary services)

**Usage**:
```bash
ansible-playbook system-admin.yml -i inventory.yml
ansible-playbook system-admin.yml -i inventory.yml --tags users
ansible-playbook system-admin.yml -i inventory.yml --tags packages
```

**Tags**: `users` | `packages` | `updates` | `ntp` | `limits` | `sysctl` | `services` | `network` | `security` | `monitoring`

---

### 2. **security-hardening.yml**
**Purpose**: Implement CIS Benchmark security controls and system hardening

**Tasks**:
- SSH hardening (disable root login, password auth)
- Firewall configuration (UFW setup)
- File permissions (critical system files)
- Audit daemon (auditd) installation & configuration
- Kernel security parameters (ExecShield, ASLR)
- SELinux/AppArmor enforcement
- Syslog configuration
- Intrusion detection basics

**Usage**:
```bash
ansible-playbook security-hardening.yml -i inventory.yml
ansible-playbook security-hardening.yml -i inventory.yml --tags ssh
ansible-playbook security-hardening.yml -i inventory.yml --tags firewall
```

**Tags**: `ssh` | `firewall` | `permissions` | `audit` | `kernel` | `selinux` | `apparmor` | `syslog` | `ids`

---

## Planned Playbooks

### 3. **monitoring-setup.yml** *(Coming Soon)*
**Purpose**: Setup comprehensive monitoring, logging, and alerting

**Features**:
- Prometheus node exporter installation
- Grafana dashboard setup
- ELK Stack (Elasticsearch, Logstash, Kibana) deployment
- Alert rule configuration
- Log aggregation setup
- Metrics collection & visualization
- Centralized logging
- Health check endpoints

---

### 4. **kubernetes-operations.yml** *(Coming Soon)*
**Purpose**: Kubernetes cluster operations and management

**Features**:
- kubeadm cluster initialization
- CNI plugin deployment (Calico, Flannel)
- Node joining & configuration
- RBAC setup
- Ingress controller installation
- Storage class configuration
- Pod security policies
- Network policies
- Certificate rotation

---

### 5. **database-backup.yml** *(Coming Soon)*
**Purpose**: Database backup, restoration, and maintenance

**Features**:
- PostgreSQL backup automation
- MySQL backup & replication
- MongoDB backup strategies
- Backup encryption & compression
- Retention policies
- Point-in-time recovery setup
- Backup verification
- Restore procedures
- WAL archiving

---

### 6. **docker-container-management.yml** *(Coming Soon)*
**Purpose**: Docker and container orchestration

**Features**:
- Docker installation & configuration
- Docker Compose setup
- Image building & pushing
- Registry configuration
- Container networking
- Volume management
- Log drivers configuration
- Container health checks
- Security scanning

---

### 7. **cloud-infrastructure.yml** *(Coming Soon)*
**Purpose**: Cloud platform operations (AWS, Azure, GCP)

**Features**:
- AWS EC2 instance management
- Azure VM operations
- GCP Compute Engine management
- Cloud storage mounting
- Instance metadata configuration
- Cloud agent installation (CloudWatch, Azure Monitor, Stackdriver)
- Auto-scaling configuration
- Load balancer setup
- VPC/VNet operations

---

### 8. **disaster-recovery.yml** *(Coming Soon)*
**Purpose**: Disaster recovery and business continuity

**Features**:
- System backup automation
- Boot recovery procedures
- Filesystem replication
- Failover testing
- RTO/RPO validation
- Disaster recovery drills
- Cross-region replication
- Data consistency checks

---

## Requirements

**Ansible Version**: >= 2.9

**Python Version**: >= 3.6

**Collections Required**:
```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```

**Dependencies**:
```bash
pip install ansible>=2.9
pip install jinja2>=2.11
pip install pyyaml>=5.1
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Manjunathsmurthy/terraform-cloud-resources.git
cd terraform-cloud-resources/ansible/sre-playbooks
```

2. Install Ansible and dependencies:
```bash
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
```

3. Prepare inventory:
```bash
# Create your inventory file
cat > inventory.yml <<EOF
all:
  children:
    production:
      hosts:
        prod-web-01:
          ansible_host: 10.0.1.10
          ansible_user: ubuntu
EOF
```

## Usage Examples

### Run All Tasks on Production Servers
```bash
ansible-playbook system-admin.yml security-hardening.yml -i inventory.yml --limit production
```

### Run Specific Tags
```bash
# Only update packages
ansible-playbook system-admin.yml -i inventory.yml --tags packages

# Only SSH hardening
ansible-playbook security-hardening.yml -i inventory.yml --tags ssh
```

### Dry-Run Mode
```bash
ansible-playbook system-admin.yml -i inventory.yml --check --diff
```

### Verbosity
```bash
# Verbose output
ansible-playbook system-admin.yml -i inventory.yml -vvv
```

## Best Practices

1. **Always Test in Non-Production**: Use `--check --diff` first
2. **Use Inventory Groups**: Organize hosts by environment/role
3. **Implement Idempotency**: Playbooks should be safe to run multiple times
4. **Version Control**: Track all changes in git
5. **Document Variables**: Use group_vars and host_vars
6. **Backup Before Running**: Take system snapshots before execution
7. **Monitor Execution**: Use callbacks and logging
8. **Review Changes**: Always verify altered systems

## Variable Customization

Create `group_vars/production.yml`:
```yaml
# System Configuration
system_users:
  - username: appuser
    groups: ['docker', 'sudo']
    shell: /bin/bash

# Package Management
packages_to_install:
  - curl
  - wget
  - git

# Monitoring
monitoring_enabled: true
metrics_interval: 60
```

## Troubleshooting

### SSH Connection Issues
```bash
ansible-playbook system-admin.yml -i inventory.yml --private-key ~/.ssh/id_rsa
```

### Privilege Escalation
```bash
ansible-playbook system-admin.yml -i inventory.yml --ask-become-pass
```

### Debug Mode
```bash
ansible-playbook system-admin.yml -i inventory.yml -vvvv --step
```

## Compliance & Security

- **CIS Benchmark**: security-hardening.yml implements CIS Level 1 & 2 controls
- **NIST Standards**: Playbooks align with NIST Cybersecurity Framework
- **SOC 2 Compliance**: Audit logging and access controls implemented
- **HIPAA Ready**: Encryption and audit trails for healthcare environments

## Contributing

To contribute new playbooks:

1. Follow the existing structure and naming conventions
2. Include comprehensive comments explaining purpose
3. Add tags for granular execution control
4. Test in multiple environments
5. Document all variables and usage
6. Submit pull request with detailed description

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or improvements:
- Open GitHub Issues
- Check existing documentation
- Review playbook comments
- Test in safe environment first

## Author

**Cloud Architect & SRE Tools**  
Maintained by: Manjunath S  
Email: contact@example.com

## Related Resources

- [Ansible Documentation](https://docs.ansible.com)
- [CIS Benchmarks](https://www.cisecurity.org/benchmarks)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Terraform Configurations](../../../terraform-cloud-resources)
