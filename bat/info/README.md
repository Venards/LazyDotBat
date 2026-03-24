# Info

Read-only scripts that display system information. All scripts require Administrator.

---

### `system_info.bat`
Full system overview in one place.
- OS version, build, architecture, uptime, install date
- Motherboard manufacturer, model, serial
- CPU name, cores, threads, speed, current usage
- RAM total, used, free, and per-slot details
- GPU name, VRAM, resolution, refresh rate, driver version
- Storage drives with usage breakdown
- Active network adapters with IP, MAC, DNS, speed
- BIOS version, date, serial
- HWID: UUID, Machine GUID, Windows product key

---

### `disk_health.bat`
Checks the health and usage of your drives.
- Physical disk health status and type (SSD/HDD)
- Logical drive usage with warning if over 90% full
- Volume health and operational status

---

### `network_info.bat`
Detailed network information and connectivity test.
- All active adapters with IP, gateway, MAC, DNS, speed
- Your current public IP
- Ping test to 8.8.8.8, 1.1.1.1, and google.com

> Requires `network_info.ps1` in the `ps1/` folder.

---

### `open_ports.bat`
Shows all open ports and what's using them.
- TCP listening ports with address, PID, and process name
- UDP endpoints with owning processes
- Active established connections with remote addresses
- Summary count of all connections
- Flags commonly abused ports (4444, 1337, 31337, etc.)

---

### `security_audit.bat`
Checks your system's security posture and flags issues.
- Firewall status per profile (Domain, Private, Public)
- Antivirus detection and status
- Windows Defender: real-time protection, tamper protection, signature age
- UAC level and status
- Remote Desktop and NLA settings
- Guest account and local admin list
- Auto-login and plaintext password detection
- SMBv1 status and non-default shares
- BitLocker encryption status
- Ports exposed on all interfaces
- Windows Update patch age
- Summary count of issues found
