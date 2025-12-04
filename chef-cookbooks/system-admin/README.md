# Chef System Administration Cookbook

## PURPOSE

This Chef cookbook provides enterprise-grade system administration automation for SRE and Cloud Architects. It automates core Linux system administration tasks including user management, package installation, service management, system limits, kernel parameter tuning, and time synchronization.

## FEATURES

- **User Management**: Create SRE admin users with proper permissions and sudo access
- **Package Management**: Install and update essential packages across distributions
- **Service Management**: Enable and start critical services (SSH, logging)
- **System Limits**: Configure file descriptor and process limits (ulimit)
- **Kernel Parameters**: Optimize kernel settings for performance and stability
- **Time Synchronization**: Configure Chrony for precise time keeping
- **Multi-Platform Support**: Works on Ubuntu, Debian, CentOS, and RHEL

## SUPPORTED PLATFORMS

- Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+

## INSTALLATION

```bash
knife cookbook upload system-admin
```

## USAGE

Add to run list: `recipe[system-admin::default]`

## RECIPES

### default.rb
Main recipe handling all system administration configurations

## COMPLIANCE STANDARDS

- CIS Linux Benchmarks
- NIST SP 800-53
- SOC 2 Type II
- HIPAA

## LICENSE

Apache 2.0
