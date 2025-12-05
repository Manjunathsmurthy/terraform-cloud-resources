#!/bin/bash
#
# Linux Log Management Script
# Purpose: Automated log rotation, compression, archival, and cleanup
# Author: Linux System Administration Team
# Compatible: RHEL 7-10, Ubuntu 18.04+, SLES 12+
#

set -euo pipefail

# Configuration
LOG_RETENTION_DAYS=30
COMPRESSION_AGE_DAYS=7
ARCHIVE_DIR="${ARCHIVE_DIR:-/var/log/archive}"
LOG_DIRS=(
    "/var/log"
    "/var/log/nginx"
    "/var/log/apache2"
    "/var/log/mysql"
    "/var/log/postgresql"
)

# Ensure archive directory exists
mkdir -p "${ARCHIVE_DIR}"

echo "=== Log Management Started ==="
echo "Log Retention: ${LOG_RETENTION_DAYS} days"
echo "Compression Age: ${COMPRESSION_AGE_DAYS} days"

# Function to rotate logs
rotate_logs() {
    local log_dir="$1"
    
    if [ ! -d "${log_dir}" ]; then
        return
    fi
    
    echo "Processing ${log_dir}..."
    
    # Find and process log files
    find "${log_dir}" -maxdepth 1 -type f -name "*.log" | while read -r logfile; do
        if [ -s "${logfile}" ]; then
            local timestamp=$(date +%Y%m%d_%H%M%S)
            local basename=$(basename "${logfile}")
            local rotated="${logfile}.${timestamp}"
            
            # Rotate the log
            mv "${logfile}" "${rotated}"
            
            # Create new empty log file with same permissions
            touch "${logfile}"
            chmod --reference="${rotated}" "${logfile}" 2>/dev/null || true
            
            echo "  ✓ Rotated: ${basename}"
        fi
    done
}

# Function to compress old logs
compress_logs() {
    local log_dir="$1"
    
    if [ ! -d "${log_dir}" ]; then
        return
    fi
    
    echo "Compressing logs in ${log_dir}..."
    
    # Find and compress logs older than specified days
    find "${log_dir}" -maxdepth 1 -type f -name "*.log.*" ! -name "*.gz" -mtime +${COMPRESSION_AGE_DAYS} | while read -r logfile; do
        echo "  Compressing: $(basename "${logfile}")"
        gzip "${logfile}"
    done
}

# Function to archive and cleanup old logs
archive_and_cleanup() {
    local log_dir="$1"
    
    if [ ! -d "${log_dir}" ]; then
        return
    fi
    
    echo "Archiving and cleaning up logs from ${log_dir}..."
    
    # Archive compressed logs older than retention period
    find "${log_dir}" -maxdepth 1 -type f -name "*.log.*.gz" -mtime +${LOG_RETENTION_DAYS} | while read -r logfile; do
        local basename=$(basename "${logfile}")
        echo "  Archiving: ${basename}"
        
        # Move to archive directory
        mv "${logfile}" "${ARCHIVE_DIR}/"
    done
    
    # Clean up uncompressed logs older than retention period
    find "${log_dir}" -maxdepth 1 -type f -name "*.log.*" ! -name "*.gz" -mtime +${LOG_RETENTION_DAYS} -delete
}

# Function to generate log statistics
generate_statistics() {
    echo ""
    echo "=== Log Statistics ==="
    echo "Total log files: $(find /var/log -type f -name '*.log' | wc -l)"
    echo "Total compressed logs: $(find /var/log -type f -name '*.gz' | wc -l)"
    echo "Archived logs: $(ls -1 "${ARCHIVE_DIR}" 2>/dev/null | wc -l)"
    echo "Archive directory size: $(du -sh "${ARCHIVE_DIR}" 2>/dev/null | awk '{print $1}')"
}

# Function to clean old archived logs
clean_old_archives() {
    echo ""
    echo "=== Cleaning Old Archives ==="
    
    local archive_retention_days=$((LOG_RETENTION_DAYS * 3))
    echo "Removing archives older than ${archive_retention_days} days..."
    
    find "${ARCHIVE_DIR}" -type f -mtime +${archive_retention_days} -delete
    echo "Old archives cleaned"
}

# Main execution
main() {
    for log_dir in "${LOG_DIRS[@]}"; do
        rotate_logs "${log_dir}"
        compress_logs "${log_dir}"
        archive_and_cleanup "${log_dir}"
    done
    
    generate_statistics
    clean_old_archives
    
    echo ""
    echo "=== Log Management Completed ==="
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Execute main function
main "$@"
