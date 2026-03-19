# Tools

Action scripts for cleaning, optimizing, and fixing your system. All scripts require Administrator.

---

### `disk_cleaner.bat`
Removes junk files and clears caches to free up disk space.
- Auto-deletes `*.tmp`, `*.log`, `Thumbs.db`, `desktop.ini`
- Optional: Downloads folder, Recycle Bin, browser caches (Chrome, Edge, Firefox, Brave, Opera, Opera GX, Vivaldi, Tor), Windows Temp, Windows Update cache, Prefetch, app caches (Discord, Spotify, Steam)
- Shows total disk space freed at the end

---

### `ram_flush.bat`
Frees up RAM that Windows holds onto after apps close.
- Forces Windows to release standby/cached memory
- Shows free RAM before and after

---

### `network_boost.bat`
Fixes common network issues and optionally improves DNS speed.
- Flushes DNS cache
- Resets Winsock and TCP/IP stack
- Lets you switch to Cloudflare (1.1.1.1) or Google (8.8.8.8) DNS

---

### `boost_for_gaming.bat`
Optimizes your PC for gaming with a one-click restore.
- Sets power plan to High Performance
- Kills background processes (OneDrive, Widgets, Search Indexer, etc.)
- Disables Xbox Game Bar
- Optimizes GPU scheduling
- Stops telemetry services
- **Option 2 restores everything back**

---

### `disable_windows_junk.bat`
Temporarily disables Windows bloatware and telemetry.
- Stops telemetry, Xbox, and feedback services
- Blocks telemetry via registry
- Kills leftover junk processes
- **Option 2 restores everything back**

---

### `gpu_reset.bat`
Restarts your GPU driver without rebooting.
- Detects all display adapters automatically
- Screen goes black briefly while driver reloads
- Fixes display freezes, artifacts, and flickering

---

### `restart_audio.bat`
Restarts the Windows audio service to fix sound issues.
- Force-kills the audio process
- Restarts both audio services cleanly
