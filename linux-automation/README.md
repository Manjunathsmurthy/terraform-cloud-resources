# Linux Automation Scripts for System Administration

Comprehensive collection of Bash automation scripts for Linux system administrators. Designed for RHEL 7-10, Ubuntu 18.04+, and SLES 12+.

## Overview

This module provides production-ready Bash scripts to automate common Linux system administration tasks, reducing manual effort and improving operational consistency.

## Scripts

### 1. system-monitoring.sh
Comprehensive system health monitoring and resource utilization tracking.

**Features:**
- CPU usage monitoring with threshold alerts
- Memory utilization tracking
- Disk space analysis per filesystem
- Load average monitoring
- Network interface and statistics review
- Process count and zombie detection
- Systemd service status verification
- Configurable alert thresholds
- Color-coded output for easy reading

**Usage:**
```bash
# Basic monitoring report
./system-monitoring.sh

# With verbose output
LOG_DIR=/custom/path ./system-monitoring.sh

# With custom thresholds
THRESHOLD_CPU=75 THRESHOLD_MEMORY=80 ./system-monitoring.sh
```

**Configurable Parameters:**
- `LOG_DIR`: Output directory for reports (default: /var/log/system-monitoring)
- `THRESHOLD_CPU`: CPU usage threshold percentage (default: 80)
- `THRESHOLD_MEMORY`: Memory usage threshold percentage (default: 85)
- `THRESHOLD_DISK`: Disk usage threshold percentage (default: 90)
- `THRESHOLD_LOAD`: Load average threshold (default: 4)

### 2. log-management.sh
Automated log rotation, compression, archival, and cleanup.

**Features:**
- Automatic log file rotation with timestamps
- Compression of old log files (gzip)
- Archive management for long-term storage
- Cleanup of expired logs
- Log statistics and reporting
- Support for multiple log directories
- Configurable retention policies
- Safe handling of permissions

**Usage:**
```bash
# Run as root (required for log management)
sudo ./log-management.sh

# With custom retention
LOG_RETENTION_DAYS=60 ./log-management.sh

# Custom archive location
ARCHIVE_DIR=/mnt/archive ./log-management.sh
```

**Configurable Parameters:**
- `LOG_RETENTION_DAYS`: Keep logs for N days (default: 30)
- `COMPRESSION_AGE_DAYS`: Compress logs older than N days (default: 7)
- `ARCHIVE_DIR`: Directory for archived logs (default: /var/log/archive)
- `LOG_DIRS`: Array of directories to manage (default: standard system log dirs)

### 3. user-management.sh
User provisioning, permission management, and security auditing.

**Features:**
- Create new users with configurable shell and groups
- List system users with UID/GID information
- Audit file permissions and find security risks
- Track sudo user access
- Monitor user login activity and failed attempts
- Disable/lock user accounts safely
- Remove users while preserving or deleting home directories
- Set recursive permissions on files/directories
- Generate comprehensive audit reports

**Usage:**
```bash
# Run as root
sudo ./user-management.sh

# Generate full audit report
sudo ./user-management.sh

# Create new user (modify script or extend with arguments)
sudo ./user-management.sh
```

**Functions Available:**
```bash
# Source the script in your shell scripts
source ./user-management.sh
create_user "newuser" "/bin/bash" "sudo,docker"
list_users
audit_permissions
list_sudo_users
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Manjunathsmurthy/terraform-cloud-resources.git
cd terraform-cloud-resources/linux-automation
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. (Optional) Copy to system-wide location:
```bash
sudo cp *.sh /usr/local/bin/
```

## Requirements

### System Requirements
- Linux kernel 4.4+
- Bash 4.0+
- Common utilities: grep, awk, sed, find, gzip, etc.

### Permissions
- `system-monitoring.sh`: Can run as regular user (limited info) or root (full info)
- `log-management.sh`: Requires root privileges
- `user-management.sh`: Requires root privileges

### Supported Distributions
- Red Hat Enterprise Linux (RHEL) 7-10
- CentOS 7-9
- Ubuntu 18.04 LTS, 20.04 LTS, 22.04 LTS
- SUSE Linux Enterprise Server (SLES) 12, 15
- Debian 9+

## Scheduling with Cron

### System Monitoring (Hourly)
```cron
0 * * * * /usr/local/bin/system-monitoring.sh >> /var/log/monitoring.log 2>&1
```

### Log Management (Daily)
```cron
2 0 * * * /usr/local/bin/log-management.sh >> /var/log/logmgmt.log 2>&1
```

### User Audit (Weekly)
```cron
0 2 * * 0 /usr/local/bin/user-management.sh >> /var/log/user-audit.log 2>&1
```

## Best Practices

1. **Regular Backups**: Back up critical log files before running log management
2. **Test First**: Test scripts in non-production environment first
3. **Review Thresholds**: Adjust alert thresholds based on your infrastructure
4. **Monitor Output**: Check script output logs regularly
5. **Version Control**: Maintain scripts in Git for audit trail
6. **Documentation**: Document any customizations made to scripts
7. **Permissions**: Carefully manage sudo access for script execution
8. **Error Handling**: Monitor for script errors in system logs

## Customization

### Adding New Monitoring Checks
Edit `system-monitoring.sh` and add new functions:
```bash
monitor_custom_service() {
    echo "Checking custom service..."
    # Your monitoring logic
}
```

### Extending Log Management
Modify `LOG_DIRS` array in `log-management.sh`:
```bash
LOG_DIRS=(
    "/var/log"
    "/var/log/nginx"
    "/var/log/postgresql"
    "/opt/myapp/logs"  # Custom application logs
)
```

## Troubleshooting

### Permission Denied
```bash
# Fix: Make scripts executable
chmod +x *.sh
```

### Script Not Finding Logs
```bash
# Check log directory exists
ls -la /var/log/

# Create missing directory
mkdir -p /var/log/archive
```

### High CPU Usage from Monitoring
```bash
# Reduce check frequency
* */2 * * * /usr/local/bin/system-monitoring.sh  # Every 2 hours
```

## Security Considerations

1. **Root Access**: Scripts requiring root should be audited carefully
2. **Log Files**: Ensure log files contain no sensitive information
3. **User Creation**: Verify users before creation in production
4. **Archive Storage**: Secure archive directory with appropriate permissions
5. **Audit Logging**: Enable systemd audit logging for all operations

## Performance Impact

- **system-monitoring.sh**: <2 seconds execution time
- **log-management.sh**: 5-30 seconds (depends on log volume)
- **user-management.sh**: <1 second for queries, 5-10 seconds for reports

## Integration with Monitoring Systems

### Prometheus
Modify scripts to output Prometheus format metrics:
```bash
echo "# HELP system_cpu_usage CPU usage percentage"
echo "# TYPE system_cpu_usage gauge"
echo "system_cpu_usage ${cpu_usage}"
```

### Elasticsearch
Forward logs to Elasticsearch:
```bash
cat /var/log/system-monitoring/*.log | logstash -c logstash.conf
```

## Contributing

Contributions welcome! Please:
1. Test scripts thoroughly
2. Follow existing code style
3. Add comments for complex logic
4. Update documentation
5. Submit pull requests

## License

Part of terraform-cloud-resources repository.

## Support

For issues or questions:
1. Check troubleshooting section
2. Review script logs in /var/log/
3. Test on non-production system first
4. Consult Linux distribution documentation

## Related Resources

- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide)
- [RHEL Documentation](https://access.redhat.com/documentation/)
- [Ubuntu Manpages](https://manpages.ubuntu.com/)
- [SLES Documentation](https://www.suse.com/documentation/)
