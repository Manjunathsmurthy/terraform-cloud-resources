#
# PURPOSE: System Administration Automation
# This Chef recipe automates core system administration tasks including user management,
# package installation, service management, system limits, kernel parameters, and time sync.
# Designed for SRE and Cloud Architect use across multi-platform Linux environments.
#

case node['platform_family']
when 'debian'
  # Ubuntu/Debian package manager
  package_manager = 'apt-get'
  package 'update-notifier-common' do
    action :purge
  end
when 'rhel'
  # CentOS/RHEL package manager
  package_manager = 'yum'
end

# ===== USER MANAGEMENT =====

# Create SRE system user
user 'sre-admin' do
  comment 'SRE Administration User'
  uid 2000
  gid 2000
  home '/home/sre-admin'
  shell '/bin/bash'
  action :create
end

# Create SRE group
group 'sre-admin' do
  gid 2000
  action :create
end

# Add sre-admin to sudoers
file '/etc/sudoers.d/sre-admin' do
  content 'sre-admin ALL=(ALL) NOPASSWD:ALL
'
  owner 'root'
  group 'root'
  mode '0440'
  action :create
end

# ===== PACKAGE MANAGEMENT =====

# Update package lists
case node['platform_family']
when 'debian'
  execute 'apt-update' do
    command 'apt-get update'
    action :run
    not_if 'test -f /tmp/.apt-updated-today'
  end
when 'rhel'
  execute 'yum-update' do
    command 'yum check-update'
    action :run
  end
end

# Install essential packages
packages_to_install = [
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

packages_to_install.each do |pkg|
  package pkg do
    action :install
  end
end

# ===== SERVICE MANAGEMENT =====

# Enable and start essential services
service 'ssh' do
  action [:enable, :start]
end

service 'rsyslog' do
  action [:enable, :start]
end

# ===== SYSTEM LIMITS =====

# Configure file descriptor limits
file '/etc/security/limits.d/50-sre.conf' do
  content '*   soft nofile 65535
*   hard nofile 65535
*   soft nproc  4096
*   hard nproc  4096
'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# ===== KERNEL PARAMETERS =====

# Optimize kernel parameters via sysctl
sysctl_params = {
  'net.ipv4.ip_forward' => 1,
  'net.ipv4.tcp_tw_reuse' => 1,
  'net.core.somaxconn' => 4096,
  'net.ipv4.tcp_max_syn_backlog' => 8192,
  'vm.swappiness' => 10,
  'kernel.panic' => 10
}

sysctl_params.each do |key, value|
  execute "sysctl #{key}" do
    command "sysctl -w #{key}=#{value}"
    action :run
  end
end

# Persist sysctl settings
file '/etc/sysctl.d/99-sre.conf' do
  content sysctl_params.map { |k, v| "#{k}=#{v}" }.join("
") + "
"
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[sysctl-apply]', :immediately
end

execute 'sysctl-apply' do
  command 'sysctl -p /etc/sysctl.d/99-sre.conf'
  action :nothing
end

# ===== TIME SYNCHRONIZATION =====

case node['platform_family']
when 'debian'
  package 'chrony' do
    action :install
  end

  template '/etc/chrony/chrony.conf' do
    source 'chrony.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, 'service[chrony]'
  end
when 'rhel'
  package 'chrony' do
    action :install
  end

  template '/etc/chrony.conf' do
    source 'chrony.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, 'service[chrony]'
  end
end

service 'chrony' do
  action [:enable, :start]
end

# ===== LOGGING =====

log "System Admin Configuration - Node: #{node['hostname']} - OS: #{node['os']} [#{node['os_version']}]" do
  level :info
end
