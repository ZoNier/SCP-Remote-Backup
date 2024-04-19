# Remote Backup Script with Cron and SCP

This script facilitates automated remote backups using `cron` and `scp` for secure file transfer over SSH.

## Usage

1. **Set up SSH Key Authentication**: Ensure that SSH key authentication is configured between the local and remote servers to allow passwordless login.

2. **Modify Script Parameters**: Open the script `scp-backup.sh` and modify the following parameters according to your setup:

    ```bash
    # Remote server details
    REMOTE_USER="backup"
    REMOTE_HOST="192.168.1.200"
    REMOTE_PORT="22"
    REMOTE_DIRECTORY="/home/backup"

    # Maximum number of backups to keep
    MAX_BACKUPS=7

    # Directories to backup
    BACKUP_DIRECTORIES=("/etc" "/home" "/opt" "/root" "/var")

    # Option to keep local copies (true or false)
    SAVE_LOCAL_COPIES=false
    ```

    - `REMOTE_USER`: Remote server username.
    - `REMOTE_HOST`: Remote server hostname or IP address.
    - `REMOTE_PORT`: SSH port of the remote server.
    - `REMOTE_DIRECTORY`: Directory path on the remote server where backups will be stored.
    - `MAX_BACKUPS`: Maximum number of backups to keep on the remote server.
    - `BACKUP_DIRECTORIES`: Array of directories to backup.
    - `SAVE_LOCAL_COPIES`: Option to keep local copies of backups.

3. **Set up Cron Job**:

    Open crontab editor by running:

    ```bash
    crontab -e
    ```

    Add the following line to schedule the script to run periodically:

    ```cron
    0 0 * * * /opt/scp-backup.sh >/dev/null 2>&1
    ```

    This example runs the backup script daily at 00:00 AM. Adjust the schedule as needed.

4. **Save and Exit**:

    Save the crontab file and exit the editor.

## Log Rotation and Improved Logging

- The script now includes log rotation to manage log file size.
- Logs are more informative and include timestamps and detailed messages.

## Notes

- Ensure that the script is executable (`chmod +x scp-backup.sh`).
- Regularly monitor the backups and adjust the retention policy (`MAX_BACKUPS`) as necessary.
- Review logs (`/var/log/backup.log`) to ensure backups are running smoothly and troubleshoot any issues.

## License
This project is licensed under the [GNU General Public License](LICENSE).
