import paramiko
import os

local_file = "bookingRoutes_clean.js"
remote_file = "/var/www/ehalisaha/backend/src/routes/bookingRoutes.js"
hostname = "185.157.46.167"
password = "acf!112621"
username = "root"

try:
    print(f"Connecting to {hostname}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=username, password=password)
    
    print("Uploading file via SFTP...")
    sftp = ssh.open_sftp()
    sftp.put(local_file, remote_file)
    sftp.close()
    print("Upload complete.")
    
    print("Restarting pm2 backend...")
    stdin, stdout, stderr = ssh.exec_command("pm2 restart ehalisaha-backend")
    print("Log:")
    print(stdout.read().decode())
    err = stderr.read().decode()
    if err:
        print("Stderr:", err)
        
    ssh.close()
    print("Process finished successfully.")
except Exception as e:
    print(f"Error: {e}")
