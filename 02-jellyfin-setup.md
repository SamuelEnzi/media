# Jellyfin Media Server Setup Guide

## Overview

Jellyfin is a free, open-source media server that streams your movies, TV shows, music, and other media to any device. This guide covers installation, configuration, and optimization.

## Installation

### Windows Installation

1. **Download Jellyfin**
   - Visit https://jellyfin.org/downloads/server
   - Download the Windows installer
   - Requires Windows 10 Version 1607 or newer

2. **Install Jellyfin**
   - Run the installer as administrator
   - Choose "Install as Windows Service" for automatic startup
   - Complete the installation

3. **Access Web Interface**
   - Open browser to `http://localhost:8096`
   - Complete initial setup wizard

### Linux Installation (Ubuntu/Debian)

1. **Install via Official Repository**
   ```bash
   # Add Jellyfin repository
   curl -fsSL https://repo.jellyfin.org/install-debuntu.sh | sudo bash
   
   # Install Jellyfin
   sudo apt update
   sudo apt install jellyfin
   ```

2. **Start Service**
   ```bash
   sudo systemctl enable jellyfin
   sudo systemctl start jellyfin
   ```

3. **Access Web Interface**
   - Open browser to `http://localhost:8096`

### macOS Installation

1. **Download Package**
   - Visit https://jellyfin.org/downloads/server
   - Download macOS package
   - Requires macOS 13.0+ (Ventura)

2. **Install and Start**
   - Install the package
   - Start Jellyfin from Applications
   - Access at `http://localhost:8096`

Source: https://jellyfin.org/docs/general/installation/

## Initial Configuration

### Setup Wizard

1. **Language and User Account**
   - Select preferred language
   - Create administrator account with strong password

2. **Media Libraries**
   - Add libraries for Movies, TV Shows, Music
   - Use these recommended paths:
     - Movies: `/data/media/movies`
     - TV Shows: `/data/media/tv`
     - Music: `/data/media/music`

3. **Metadata Settings**
   - Enable automatic metadata downloading
   - Select preferred metadata providers (The Movie Database, The TV Database, etc.)

4. **Remote Access**
   - Enable automatic port forwarding (UPnP) if desired
   - Configure external access if needed

### Essential Settings

#### General Configuration

1. **Dashboard → General**
   - Server name: Choose descriptive name
   - Cache path: Default is fine
   - Log level: Information (change to Debug only for troubleshooting)

2. **Dashboard → Networking**
   - Local network addresses: Add your network subnet (e.g., 192.168.1.0/24)
   - Published server URL: Set if accessing externally
   - Enable automatic port mapping: Only if using UPnP

#### Hardware Acceleration

**Intel Quick Sync (Recommended)**

1. **Dashboard → Playback**
   - Hardware acceleration: Intel Quick Sync Video
   - Enable hardware decoding for: H264, HEVC, VP9, AV1 (if supported)
   - Enable hardware encoding: Yes
   - Enable VPP tone mapping: Yes (for HDR content)

2. **Verify GPU Access (Linux)**
   ```bash
   # Check if GPU is accessible
   ls -la /dev/dri/
   
   # Add jellyfin user to render group
   sudo usermod -a -G render jellyfin
   sudo systemctl restart jellyfin
   ```

**NVIDIA Graphics**

1. **Install NVIDIA Container Runtime (if using Docker)**
   - Follow: https://github.com/NVIDIA/nvidia-container-toolkit

2. **Dashboard → Playback**
   - Hardware acceleration: NVIDIA NVENC
   - Enable hardware decoding for supported codecs
   - Enable hardware encoding: Yes

**Avoid AMD Graphics**
- AMD has poor encoder quality and driver support
- Use Intel or NVIDIA instead

Source: https://jellyfin.org/docs/general/administration/hardware-selection

## Directory Structure and Permissions

### Recommended Structure
```
/data/
├── media/
│   ├── movies/
│   │   ├── Movie Name (2023)/
│   │   │   └── Movie Name (2023).mkv
│   │   └── ...
│   ├── tv/
│   │   ├── Series Name/
│   │   │   ├── Season 01/
│   │   │   │   ├── Series Name - S01E01 - Episode Name.mkv
│   │   │   │   └── ...
│   │   │   └── Season 02/
│   │   └── ...
│   └── music/
│       ├── Artist Name/
│       │   ├── Album Name/
│       │   │   ├── 01 - Track Name.flac
│       │   │   └── ...
│       │   └── ...
│       └── ...
└── jellyfin/
    └── config/
```

### Linux Permissions

```bash
# Create media directories
sudo mkdir -p /data/media/{movies,tv,music}
sudo mkdir -p /data/jellyfin/config

# Set ownership (replace 'username' with your user)
sudo chown -R username:username /data/media
sudo chown -R jellyfin:jellyfin /data/jellyfin

# Set permissions
sudo chmod -R 755 /data/media
sudo chmod -R 750 /data/jellyfin
```

## Library Configuration

### Movie Library

1. **Add Library**
   - Type: Movies
   - Display name: Movies
   - Folders: `/data/media/movies`

2. **Advanced Settings**
   - Preferred metadata language: English (or your preference)
   - Country: Your country
   - Enable real time monitoring: Yes
   - Metadata providers: The Movie Database, Open Movie Database

### TV Show Library

1. **Add Library**
   - Type: TV Shows
   - Display name: TV Shows  
   - Folders: `/data/media/tv`

2. **Advanced Settings**
   - Season zero display name: Specials
   - Metadata providers: The TV Database, The Movie Database
   - Enable real time monitoring: Yes

### Music Library

1. **Add Library**
   - Type: Music
   - Display name: Music
   - Folders: `/data/media/music`

2. **Advanced Settings**
   - Metadata providers: MusicBrainz, Last.fm
   - Enable real time monitoring: Yes

## Performance Optimization

### Transcoding Settings

1. **Dashboard → Playback**
   - Transcoding thread count: Auto (or CPU cores - 1)
   - Hardware acceleration: Enable if available
   - Allow encoding in HEVC format: Yes (for better compression)

2. **Client Settings**
   - Max streaming bitrate: Set based on network (20 Mbps for 4K, 10 Mbps for 1080p)
   - Allow direct play: Yes
   - Allow direct stream: Yes

### Storage Optimization

1. **SSD for Jellyfin Data**
   - Store Jellyfin database and cache on SSD
   - Media files can be on slower storage

2. **Transcoding Cache**
   - Set transcoding temp directory to SSD
   - Dashboard → Playbook → Transcoding temporary path

## Networking and Security

### Port Configuration

Default ports:
- HTTP: 8096
- HTTPS: 8920 (requires SSL certificate)
- Service discovery: 7359/UDP
- DLNA: 1900/UDP

### Firewall Configuration (Linux)

```bash
# Allow Jellyfin ports
sudo ufw allow 8096/tcp
sudo ufw allow 7359/udp
sudo ufw allow 1900/udp
```

### SSL/HTTPS Setup (Optional)

1. **Generate Certificate**
   ```bash
   # Self-signed certificate (development only)
   sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout /etc/jellyfin/jellyfin.key \
     -out /etc/jellyfin/jellyfin.crt
   ```

2. **Dashboard → Networking**
   - Enable HTTPS: Yes
   - Certificate path: `/etc/jellyfin/jellyfin.crt`
   - Certificate key path: `/etc/jellyfin/jellyfin.key`

## Client Apps

Jellyfin supports numerous client applications:

**Desktop:**
- Web browser (any modern browser)
- Jellyfin Media Player (Windows, macOS, Linux)

**Mobile:**
- Android: Jellyfin for Android
- iOS: Jellyfin Mobile

**TV/Streaming:**
- Roku, Apple TV, Android TV
- Samsung Tizen, LG webOS
- Kodi plugin available

**Gaming:**
- Xbox One/Series X|S

Source: https://jellyfin.org/downloads/clients

## Maintenance

### Regular Tasks

1. **Update Jellyfin**
   ```bash
   # Linux (APT)
   sudo apt update && sudo apt upgrade jellyfin
   
   # Restart service
   sudo systemctl restart jellyfin
   ```

2. **Clean Database**
   - Dashboard → Scheduled Tasks → Scan Media Library
   - Run periodically to detect new/removed files

3. **Monitor Logs**
   ```bash
   # Linux logs location
   sudo tail -f /var/log/jellyfin/jellyfin.log
   ```

### Backup

**Critical Files to Backup:**
- Database: `/var/lib/jellyfin/data/jellyfin.db`
- Configuration: `/etc/jellyfin/`
- User data: `/var/lib/jellyfin/`

```bash
# Backup script example
sudo tar -czf jellyfin-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/jellyfin/ /etc/jellyfin/
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   ```bash
   # Fix ownership
   sudo chown -R jellyfin:jellyfin /var/lib/jellyfin
   sudo chown -R jellyfin:jellyfin /data/media
   ```

2. **Hardware Acceleration Not Working**
   - Verify GPU drivers are installed
   - Check if jellyfin user has access to `/dev/dri`
   - Review logs for hardware acceleration errors

3. **Cannot Connect Remotely**
   - Check firewall settings
   - Verify port forwarding
   - Set correct published server URL

4. **High CPU Usage During Playback**
   - Enable hardware acceleration
   - Reduce transcoding quality
   - Use direct play when possible

### Log Analysis

```bash
# View current logs
sudo journalctl -u jellyfin.service -f

# View logs for specific time
sudo journalctl -u jellyfin.service --since "2 hours ago"
```

## Integration with Automation Tools

Jellyfin will automatically detect new media files added to configured library folders. This makes it ideal for integration with Sonarr, Radarr, and Lidarr which will:

1. Download content via torrent clients
2. Move completed downloads to media directories
3. Jellyfin automatically scans and adds to library
4. Metadata is automatically downloaded and organized

Proceed to the next guide: **[Automation Tools Setup](./03-automation-tools-setup.md)**