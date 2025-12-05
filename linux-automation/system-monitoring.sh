#!/bin/bash
#
# Linux System Monitoring Script
# Purpose: Comprehensive system health monitoring, resource utilization tracking, and alerts
# Author: Linux System Administration Team
# Compatible: RHEL 7-10, Ubuntu 18.04+, SLES 12+
#

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="${LOG_DIR:-/var/log/system-monitoring}"
REPORT_FILE="${LOG_DIR}/system_report_$(date +%Y%m%d_%H%M%S).log"
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90
THRESHOLD_LOAD=4

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${REPORT_FILE}"
}

# Error handling
error_exit() {
    log_message "ERROR" "$1"
    exit 1
}

# ==========================================
# CPU Monitoring
# ==========================================
monitor_cpu() {
    echo -e "\n${BLUE}=== CPU Monitoring ===${NC}" | tee -a "${REPORT_FILE}"
    log_message "INFO" "Analyzing CPU utilization..."
    
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)
    echo -e "Current CPU Usage: ${cpu_usage}%" | tee -a "${REPORT_FILE}"
    
    if [ "${cpu_usage}" -gt "${THRESHOLD_CPU}" ]; then
        echo -e "${RED}⚠️  HIGH CPU USAGE: ${cpu_usage}%${NC}" | tee -a "${REPORT_FILE}"
        log_message "WARNING" "CPU usage exceeds threshold: ${cpu_usage}%"
        show_top_cpu_processes
    fi
}

show_top_cpu_processes() {
    echo -e "\nTop CPU consuming processes:" | tee -a "${REPORT_FILE}"
    ps aux --sort=-%cpu | head -11 | tee -a "${REPORT_FILE}"
}

# ==========================================
# Memory Monitoring
# ==========================================
monitor_memory() {
    echo -e "\n${BLUE}=== Memory Monitoring ===${NC}" | tee -a "${REPORT_FILE}"
    log_message "INFO" "Analyzing memory utilization..."
    
    local mem_info=$(free -h | grep Mem)
    echo -e "${mem_info}" | tee -a "${REPORT_FILE}"
    
    local mem_used=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
    echo -e "Memory Usage: ${mem_used}%" | tee -a "${REPORT_FILE}"
    
    if [ "${mem_used}" -gt "${THRESHOLD_MEMORY}" ]; then
        echo -e "${RED}⚠️  HIGH MEMORY USAGE: ${mem_used}%${NC}" | tee -a "${REPORT_FILE}"
        log_message "WARNING" "Memory usage exceeds threshold: ${mem_used}%"
        show_top_memory_processes
    fi
}

show_top_memory_processes() {
    echo -e "\nTop memory consuming processes:" | tee -a "${REPORT_FILE}"
    ps aux --sort=-%mem | head -11 | tee -a "${REPORT_FILE}"
}

# ==========================================
# Disk Space Monitoring
# ==========================================
monitor_disk() {
    echo -e "\n${BLUE}=== Disk Space Monitoring ===${NC}" | tee -a "${REPORT_FILE}"
    log_message "INFO" "Analyzing disk utilization..."
    
    echo -e "\nFilesystem usage:" | tee -a "${REPORT_FILE}"
    df -h | tee -a "${REPORT_FILE}"
    
    # Check for partitions exceeding threshold
    df -h | tail -n +2 | while read line; do
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        filesystem=$(echo "$line" | awk '{print $1}')
        mountpoint=$(echo "$line" | awk '{print $6}')
        
        if [ "${usage}" -gt "${THRESHOLD_DISK}" ]; then
            echo -e "${RED}⚠️  HIGH DISK USAGE on ${filesystem} (${mountpoint}): ${usage}%${NC}" | tee -a "${REPORT_FILE}"
            log_message "WARNING" "Disk usage on ${mountpoint} exceeds threshold: ${usage}%"
        fi
    done
}

# ==========================================
# Load Average Monitoring
# ==========================================
monitor_load() {
    echo -e "\n${BLUE}=== Load Average Monitoring ===${NC}" | tee -a "${REPORT_FILE}"
    
    local load_avg=$(cat /proc/loadavg)
    echo -e "Load Average: ${load_avg}" | tee -a "${REPORT_FILE}"
    
    local current_load=$(echo "${load_avg}" | awk '{printf("%.2f", $1)}')
    local cpu_count=$(nproc)
    
    echo -e "CPU Cores: ${cpu_count}" | tee -a "${REPORT_FILE}"
    
    if (( $(echo "${current_load} > ${THRESHOLD_LOAD}" | bc -l) )); then
        echo -e "${RED}⚠️  HIGH LOAD AVERAGE: ${current_load}${NC}" | tee -a "${REPORT_FILE}"
        log_message "WARNING" "Load average exceeds threshold: ${current_load}"
    fi
}

# ==========================================
# Network Monitoring
# ==========================================
monitor_network() {
    echo -e "\n${BLUE}=== Network Monitoring ===${NC}" | tee -a "${REPORT_FILE}"
    log_message "INFO" "Analyzing network interfaces..."
    
    ip -br addr show | tee -a "${REPORT_FILE}"
    
    echo -e "\nNetwork Statistics:" | tee -a "${REPORT_FILE}"
    netstat -s 2>/dev/null | head -20 | tee -a "${REPORT_FILE}" || ss -s | tee -a "${REPORT_FILE}"
}

# ==========================================
# Process Monitoring
# ==========================================
monitor_processes() {
    echo -e "\n${BLUE}=== Process Monitoring ===${NC}" | tee -a "${REPORT_FILE}"
    log_message "INFO" "Monitoring system processes..."
    
    local total_procs=$(ps aux | wc -l)
    local running_procs=$(ps -e -o stat= | grep -c '^R')
    local zombie_procs=$(ps aux | grep -c 'Z' || true)
    
    echo -e "Total Processes: ${total_procs}" | tee -a "${REPORT_FILE}"
    echo -e "Running Processes: ${running_procs}" | tee -a "${REPORT_FILE}"
    echo -e "Zombie Processes: ${zombie_procs}" | tee -a "${REPORT_FILE}"
    
    if [ "${zombie_procs}" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Zombie processes detected: ${zombie_procs}${NC}" | tee -a "${REPORT_FILE}"
        log_message "WARNING" "Zombie processes found: ${zombie_procs}"
    fi
}

# ==========================================
# System Information
# ==========================================
show_system_info() {
    echo -e "\n${BLUE}=== System Information ===${NC}" | tee -a "${REPORT_FILE}"
    
    echo -e "Hostname: $(hostname)" | tee -a "${REPORT_FILE}"
    echo -e "Kernel: $(uname -r)" | tee -a "${REPORT_FILE}"
    echo -e "Uptime: $(uptime -p)" | tee -a "${REPORT_FILE}"
    echo -e "Distribution: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')" | tee -a "${REPORT_FILE}"
}

# ==========================================
# Systemd Services Monitoring
# ==========================================
monitor_services() {
    echo -e "\n${BLUE}=== Systemd Services Status ===${NC}" | tee -a "${REPORT_FILE}"
    
    local failed_services=$(systemctl list-units --state=failed --no-pager | grep -c FAILED || echo 0)
    
    if [ "${failed_services}" -gt 0 ]; then
        echo -e "${RED}⚠️  Failed Services: ${failed_services}${NC}" | tee -a "${REPORT_FILE}"
        systemctl list-units --state=failed --no-pager | tee -a "${REPORT_FILE}"
    else
        echo -e "${GREEN}✓ All services running${NC}" | tee -a "${REPORT_FILE}"
    fi
}

# ==========================================
# Main Execution
# ==========================================
main() {
    echo -e "${GREEN}Starting System Monitoring Report${NC}"
    echo -e "Report saved to: ${REPORT_FILE}\n"
    
    log_message "INFO" "=== System Monitoring Report Started ==="
    show_system_info
    monitor_load
    monitor_cpu
    monitor_memory
    monitor_disk
    monitor_network
    monitor_processes
    monitor_services
    
    log_message "INFO" "=== System Monitoring Report Completed ==="
    echo -e "\n${GREEN}Report generation completed!${NC}"
}

# Execute main function
main "$@"
