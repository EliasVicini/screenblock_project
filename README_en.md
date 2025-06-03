# User Session Control - ScreenBlock

This project is a PowerShell script designed to control session time for users on Windows workstations in a corporate network. It limits usage time per user and enforces logoff once the allowed time is exceeded.

---

## 📂 Project Structure

```
.
├── tempocorrido.ps1        # Main script
├── Users.config            # Time configuration per user (e.g., user;HH:MM)
├── Logs/                   # Folder containing .json state files and .log logs
```

---

## ⚙️ How It Works

- The script is executed via GPO at user logon and every 5 minutes.
- It reads the `Users.config` to determine each user's allowed time.
- Each user has a JSON file (`user.json`) with:
  - Accumulated time (`ConsumedSeconds`)
  - Last check timestamp (`LastCheck`)
  - Lock status (`Blocked`)
- When time is exceeded, the script shows a warning and logs the user off.
- Logs are written to `Logs/user.log`.

---

## ⏲️ Daily Cleanup (cron)

A cron job deletes all `.json` files daily at 23:00:

```bash
0 23 * * * root find /mnt/screenblock/Logs -name "*.json" -delete
```

## 🖥️ Requirements

- Windows with PowerShell
- Network share accessible for `Users.config` and `Logs/`
- Write permission to `\\server\\screenblock\\Logs`

---

## 🚀 How to Use

1. Deploy the script to `C:\Script\tempocorrido.ps1` using GPO.
2. Create a scheduled task named `tela_de_bloqueio` to run every 5 minutes.
3. Populate `Users.config` with users and time limits.
4. (Optional) Set up daily cron cleanup on the server.

---

## 📄 License

MIT License. See LICENSE file for details.