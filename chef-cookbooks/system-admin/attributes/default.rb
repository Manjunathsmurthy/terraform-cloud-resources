#
# PURPOSE: System Administration Cookbook Attributes
# Default attributes for the system-admin Chef cookbook
# These attributes define customizable values for user creation, packages, services,
# and kernel parameters. Customize these values per environment or node.
#

# ===== USER CONFIGURATION =====
default['sre']['admin_user'] = 'sre-admin'
default['sre']['admin_uid'] = 2000
default['sre']['admin_gid'] = 2000
default['sre']['admin_home'] = '/home/sre-admin'
default['sre']['admin_shell'] = '/bin/bash'

# ===== PACKAGE CONFIGURATION =====
default['sre']['packages'] = [
  'curl',
  'wget',
  'git',
  'vim',
  'net-tools',
  'htop',
  'jq',
  'unzip',
  'ca-certificates'
]

# ===== SERVICE CONFIGURATION =====
default['sre']['services'] = [
  'ssh',
  'rsyslog'
]

# ===== KERNEL PARAMETER CONFIGURATION =====
default['sre']['sysctl_params'] = {
  'net.ipv4.ip_forward' => 1,
  'net.ipv4.tcp_tw_reuse' => 1,
  'net.core.somaxconn' => 4096,
  'net.ipv4.tcp_max_syn_backlog' => 8192,
  'vm.swappiness' => 10,
  'kernel.panic' => 10
}

# ===== SYSTEM LIMITS =====
default['sre']['limits']['nofile'] = 65535
default['sre']['limits']['nproc'] = 4096

# ===== TIME SYNC CONFIGURATION =====
default['sre']['chrony_enabled'] = true
default['sre']['chrony_servers'] = [
  'pool.ntp.org',
  'time.nist.gov'
]
