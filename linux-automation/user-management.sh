#!/bin/bash
#
# Linux User and Permission Management Script
# Purpose: Automated user provisioning, permission management, and audit
# Author: Linux System Administration Team
# Compatible: RHEL 7-10, Ubuntu 18.04+, SLES 12+
#

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Linux User and Permission Management ===${NC}"

# Function: Create new user with SSH key
create_user() {
    local username="$1"
    local shell="${2:-/bin/bash}"
    local groups="${3:-}"
    
    echo -e "\n${BLUE}Creating user: ${username}${NC}"
    
    if id "${username}" &>/dev/null; then
        echo -e "${YELLOW}User ${username} already exists${NC}"
        return 1
    fi
    
    # Create user
    useradd -m -s "${shell}" "${username}"
    echo -e "${GREEN}✓ User ${username} created${NC}"
    
    # Add to groups if specified
    if [ -n "${groups}" ]; then
        usermod -aG "${groups}" "${username}"
        echo -e "${GREEN}✓ Added to groups: ${groups}${NC}"
    fi
    
    # Create SSH directory
    mkdir -p "/home/${username}/.ssh"
    chmod 700 "/home/${username}/.ssh"
    chown -R "${username}:${username}" "/home/${username}/.ssh"
    echo -e "${GREEN}✓ SSH directory created${NC}"
}

# Function: List all users and their details
list_users() {
    echo -e "\n${BLUE}=== System Users ===${NC}"
    echo "Format: Username | UID | GID | Home | Shell"
    echo "---------------------------------------------"
    getent passwd | grep -E ':[0-9]{4}:' | awk -F: '{printf "%-20s | %5d | %5d | %-20s | %s\\n", $1, $3, $4, $6, $7}'
}

# Function: Audit user permissions
audit_permissions() {
    echo -e "\n${BLUE}=== Permission Audit ===${NC}"
    
    # Check for files with world-writable permissions
    echo -e "\nFiles with world-writable permissions (potential security risk):"
    find / -xdev -type f -perm -002 2>/dev/null | head -20
    
    # Check for SUID binaries
    echo -e "\nSUID binaries on system:"
    find / -xdev -type f -perm -4000 2>/dev/null | wc -l
}

# Function: List sudo users
list_sudo_users() {
    echo -e "\n${BLUE}=== Sudo Users ===${NC}"
    getent group sudo 2>/dev/null | awk -F: '{print "Sudo Group: " $4}'
    getent group wheel 2>/dev/null | awk -F: '{print "Wheel Group: " $4}'
}

# Function: Check user login activity
check_user_activity() {
    local username="$1"
    
    echo -e "\n${BLUE}=== Login Activity for ${username} ===${NC}"
    
    # Last login
    lastlog -u "${username}" 2>/dev/null || echo "No login history"
    
    # Failed login attempts
    echo -e "\nFailed login attempts:"
    grep "${username}" /var/log/auth.log 2>/dev/null | grep "Failed" | tail -5 || echo "No failed attempts found"
}

# Function: Disable user account
disable_user() {
    local username="$1"
    
    echo -e "\n${BLUE}Disabling user: ${username}${NC}"
    
    if ! id "${username}" &>/dev/null; then
        echo -e "${RED}User ${username} does not exist${NC}"
        return 1
    fi
    
    # Lock the account
    usermod -L "${username}"
    echo -e "${GREEN}✓ User ${username} account locked${NC}"
    
    # Disable shell login
    usermod -s /usr/sbin/nologin "${username}"
    echo -e "${GREEN}✓ Shell access disabled${NC}"
}

# Function: Remove user
remove_user() {
    local username="$1"
    local remove_home="${2:-n}"
    
    echo -e "\n${BLUE}Removing user: ${username}${NC}"
    
    if ! id "${username}" &>/dev/null; then
        echo -e "${RED}User ${username} does not exist${NC}"
        return 1
    fi
    
    if [ "${remove_home}" == "y" ]; then
        userdel -r "${username}"
        echo -e "${GREEN}✓ User ${username} and home directory removed${NC}"
    else
        userdel "${username}"
        echo -e "${GREEN}✓ User ${username} removed (home directory retained)${NC}"
    fi
}

# Function: Set file permissions recursively
set_permissions() {
    local path="$1"
    local user="$2"
    local group="$3"
    local perms="$4"
    
    echo -e "\n${BLUE}Setting permissions on ${path}${NC}"
    
    if [ ! -e "${path}" ]; then
        echo -e "${RED}Path ${path} does not exist${NC}"
        return 1
    fi
    
    chown -R "${user}:${group}" "${path}"
    chmod -R "${perms}" "${path}"
    
    echo -e "${GREEN}✓ Permissions set${NC}"
}

# Function: Generate user audit report
generate_audit_report() {
    local report_file="/tmp/user_audit_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "\n${BLUE}Generating audit report: ${report_file}${NC}"
    
    {
        echo "=== User and Permission Audit Report ==="
        echo "Generated: $(date)"
        echo ""
        
        echo "=== System Users ==="
        getent passwd | grep -E ':[0-9]{4}:' | wc -l
        echo ""
        
        echo "=== Sudo Users ==="
        getent group sudo 2>/dev/null | awk -F: '{print $4}'
        echo ""
        
        echo "=== Last System Logins ==="
        last -n 10
        echo ""
        
        echo "=== Failed Login Attempts ==="
        grep "Failed" /var/log/auth.log 2>/dev/null | tail -20 || echo "None found"
        
    } > "${report_file}"
    
    echo -e "${GREEN}✓ Report saved to ${report_file}${NC}"
    cat "${report_file}"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}=== User Management Menu ===${NC}"
    echo "1. Create new user"
    echo "2. List all users"
    echo "3. Audit file permissions"
    echo "4. List sudo users"
    echo "5. Check user activity"
    echo "6. Disable user"
    echo "7. Remove user"
    echo "8. Generate audit report"
    echo "9. Exit"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Display information if no arguments
if [ $# -eq 0 ]; then
    list_users
    list_sudo_users
    generate_audit_report
fi
