# SaltStack State: system_admin
# PURPOSE: System Administration Automation

# User Management
sre_admin_group:
  group.present:
    - gid: 2000

sre_admin_user:
  user.present:
    - uid: 2000
    - gid: 2000
    - home: /home/sre-admin
    - shell: /bin/bash

sre_admin_sudoers:
  file.managed:
    - name: /etc/sudoers.d/sre-admin
    - mode: '0440'
    - contents: 'sre-admin ALL=(ALL) NOPASSWD:ALL'

# Package Management
system_packages:
  pkg.installed:
    - pkgs:
      - curl
      - wget
      - git
      - vim
      - net-tools
      - htop
      - jq
      - unzip
      - ca-certificates

# Service Management
ssh_service:
  service.running:
    - name: ssh
    - enable: True

rsyslog_service:
  service.running:
    - name: rsyslog
    - enable: True

# System Limits
system_limits:
  file.managed:
    - name: /etc/security/limits.d/50-sre.conf
    - contents: |
        *   soft nofile 65535
        *   hard nofile 65535
        *   soft nproc  4096
        *   hard nproc  4096

# Kernel Parameters
kernel_network_params:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
