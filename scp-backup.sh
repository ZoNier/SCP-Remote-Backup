#!/bin/bash

# Define log file
LOG_FILE="/var/log/backup.log"
MAX_LOG_LINES=1000

# Function to rotate log file if it exceeds maximum lines
rotate_log() {
    if [ "$(wc -l < "$LOG_FILE")" -gt "$MAX_LOG_LINES" ]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
        touch "$LOG_FILE"
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Log file rotated" >> "$LOG_FILE"
    fi
}

# Function to log messages
log_message() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Remote server details
REMOTE_USER="u369262-sub1"
REMOTE_HOST="u369262.your-storagebox.de"
REMOTE_PORT="23"
REMOTE_DIRECTORY="/home"

# Maximum number of backups to keep
MAX_BACKUPS=7

# Directories to backup
BACKUP_DIRECTORIES=("/etc" "/home" "/opt" "/root" "/var")

# Option to keep local copies (true or false)
SAVE_LOCAL_COPIES=false

# Remove old backup directories in /tmp if SAVE_LOCAL_COPIES is false
if [ "$SAVE_LOCAL_COPIES" = false ]; then
    find /tmp -maxdepth 1 -type d -name "backup_*" -exec rm -rf {} +
    log_message "Old temporary backup directories removed from /tmp"
fi

# Create timestamp for backup
NOW=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_DIR_NAME="backup_$NOW"

# Local backup directory
BACKUPS_DIRECTORY="/tmp/$BACKUP_DIR_NAME"

# Rotate log file if needed
rotate_log

# Create backup directory on local machine and remote server
mkdir -p "$BACKUPS_DIRECTORY" && log_message "Local backup directory created: $BACKUPS_DIRECTORY" || { log_message "Failed to create local backup directory"; exit 1; }
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIRECTORY/$BACKUP_DIR_NAME" && log_message "Remote backup directory created: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIRECTORY/$BACKUP_DIR_NAME" || { log_message "Failed to create remote backup directory"; exit 1; }

# Loop through each directory to backup
for DIR in "${BACKUP_DIRECTORIES[@]}"
do
    # Create tar archive of directory
    ARCHIVE_NAME="$(basename "$DIR").tar.gz"
    tar -czf "$BACKUPS_DIRECTORY/$ARCHIVE_NAME" -C "$(dirname "$DIR")" "$(basename "$DIR")" && log_message "Tar archive created for $DIR: $BACKUPS_DIRECTORY/$ARCHIVE_NAME" || { log_message "Failed to create tar archive for $DIR"; exit 1; }

    # Transfer archive to remote server using scp
    scp -P "$REMOTE_PORT" "$BACKUPS_DIRECTORY/$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIRECTORY/$BACKUP_DIR_NAME" && log_message "Archive transferred for $DIR to remote server: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIRECTORY/$BACKUP_DIR_NAME" || { log_message "Failed to transfer archive for $DIR to remote server"; exit 1; }
done

# Clean up local backup archive if SAVE_LOCAL_COPIES is false
if [ "$SAVE_LOCAL_COPIES" = false ]; then
    rm -rf "$BACKUPS_DIRECTORY" && log_message "Local backup directory deleted: $BACKUPS_DIRECTORY" || { log_message "Failed to delete local backup directory"; exit 1; }
fi

# Get list of backup directories on remote server sorted by modification time
REMOTE_BACKUP_DIRS=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "ls -dt $REMOTE_DIRECTORY/backup_*")

# Convert output to array
readarray -t REMOTE_BACKUP_ARRAY <<<"$REMOTE_BACKUP_DIRS"

# Sort backup directories by modification time (oldest first)
IFS=$'\n' sorted_backups=($(sort <<<"${REMOTE_BACKUP_ARRAY[*]}"))

# Calculate number of backups to remove
NUM_BACKUPS=$((${#sorted_backups[@]} - MAX_BACKUPS))

# Remove old backups on remote server if necessary
if [ "$NUM_BACKUPS" -gt 0 ]; then
    for ((i = 0; i < NUM_BACKUPS; i++)); do
        ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm -rf ${sorted_backups[i]}" && log_message "Old backup removed on remote server: ${sorted_backups[i]}" || { log_message "Failed to remove old backup ${sorted_backups[i]} on remote server"; exit 1; }
    done
fi

# Log success
log_message "Backup completed successfully"
