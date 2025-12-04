# Class: system_admin
# PURPOSE: System Administration Automation
class system_admin (
  String $admin_user = 'sre-admin',
  Integer $admin_uid = 2000,
  Array[String] $packages = ['curl', 'wget', 'git', 'vim', 'net-tools', 'htop', 'jq', 'unzip', 'ca-certificates'],
  Array[String] $services = ['ssh', 'rsyslog'],
  Hash[String, Integer] $sysctl_params = {
    'net.ipv4.ip_forward' => 1,
    'net.ipv4.tcp_tw_reuse' => 1,
    'net.core.somaxconn' => 4096,
    'net.ipv4.tcp_max_syn_backlog' => 8192,
    'vm.swappiness' => 10,
    'kernel.panic' => 10
  },
) {
  group { $admin_user:
    ensure => present,
    gid    => $admin_uid,
  }

  user { $admin_user:
    ensure => present,
    uid    => $admin_uid,
    gid    => $admin_uid,
    home   => "/home/${admin_user}",
    shell  => '/bin/bash',
    require => Group[$admin_user],
  }

  file { "/etc/sudoers.d/${admin_user}":
    ensure => file,
    owner => 'root',
    mode => '0440',
    content => "${admin_user} ALL=(ALL) NOPASSWD:ALL\n",
  }

  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure => running,
    enable => true,
  }

  file { '/etc/security/limits.d/50-sre.conf':
    ensure => file,
    owner => 'root',
    mode => '0644',
    content => "*   soft nofile 65535\n*   hard nofile 65535\n*   soft nproc  4096\n*   hard nproc  4096\n",
  }

  $sysctl_params.each |$param, $value| {
    sysctl { $param:
      value => $value,
    }
  }
}
