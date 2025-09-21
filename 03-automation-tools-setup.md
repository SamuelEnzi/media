# Automation Tools Setup Guide

## Overview

This guide covers setting up Sonarr (TV shows), Radarr (movies), Lidarr (music), and qBittorrent for automated media downloading and management. These tools work together to automatically search, download, and organize your media collection.

## qBittorrent Setup

qBittorrent is the torrent client that will handle all downloads. Set this up first as other tools depend on it.

### Installation

**Windows:**
1. Download from https://www.qbittorrent.org/
2. Install with default settings
3. Access web interface at `http://localhost:8080`

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install qbittorrent-nox

# Start service
sudo systemctl enable qbittorrent-nox@username
sudo systemctl start qbittorrent-nox@username
```

**macOS:**
1. Download from https://www.qbittorrent.org/
2. Install application
3. Enable web UI in preferences

### Configuration

1. **Web UI Access**
   - Default login: `admin` / `adminadmin`
   - Change password immediately: Options → Web UI → Authentication

2. **Download Settings**
   - Options → Downloads
   - Default save path: `/data/torrents/incomplete`
   - Keep incomplete torrents in: `/data/torrents/incomplete` 
   - Copy completed torrents to: `/data/torrents/complete`
   - Automatically add torrents from: `/data/torrents/watch`

3. **Connection Settings**
   - Options → Connection
   - Port: 8999 (or any available port)
   - Enable UPnP/NAT-PMP: Yes (unless using VPN)
   - Use different port for incoming connections: Yes

4. **BitTorrent Settings**
   - Options → BitTorrent
   - Privacy → Enable DHT: Yes
   - Privacy → Enable PEX: Yes
   - Privacy → Enable LSD: Yes
   - Seeding limits → When ratio reaches: 2.0 (or your preference)

5. **Advanced Settings**
   - Options → Advanced
   - Network interface: Select VPN interface if using VPN
   - Validate HTTPS tracker certificates: No (some trackers use self-signed certificates)

Source: https://github.com/qbittorrent/qBittorrent/wiki

## Sonarr Setup (TV Shows)

### Installation

**Windows:**
1. Download installer from https://sonarr.tv/
2. Install with default settings
3. Access at `http://localhost:8989`

**Linux:**
```bash
# Add GPG key and repository
wget -qO- https://apt.sonarr.tv/ubuntu/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/sonarr-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/sonarr-keyring.gpg] https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list

# Install
sudo apt update
sudo apt install sonarr

# Start service
sudo systemctl enable sonarr
sudo systemctl start sonarr
```

### Initial Configuration

1. **Media Management**
   - Settings → Media Management
   - Root folders: Add `/data/media/tv`
   - Episode naming: Enable renaming
   - Standard episode format: `{Series Title} - S{season:00}E{episode:00} - {Episode Title}`
   - Season folder format: `Season {season:00}`

2. **Download Clients**
   - Settings → Download Clients
   - Add qBittorrent:
     - Name: qBittorrent
     - Host: localhost
     - Port: 8080
     - Username: admin
     - Password: (your qBittorrent password)
     - Category: tv
   - Remote path mappings (if needed): Map `/data/torrents/complete/tv` to local path

3. **Indexers**
   - Will be configured after setting up Prowlarr/Jackett
   - Settings → Indexers → Add indexers

4. **General Settings**
   - Settings → General
   - Start-up: Launch browser and open app
   - Security: Set authentication if desired
   - Updates: Automatic updates enabled

### Quality Profiles

1. **Create Custom Profile**
   - Settings → Profiles
   - Add new quality profile
   - Name: "1080p Preferred"
   - Allowed qualities: HDTV-1080p, WEB-1080p, Bluray-1080p
   - Upgrades allowed: Yes
   - Quality order: Bluray-1080p (highest) → WEB-1080p → HDTV-1080p

Source: https://wiki.servarr.com/sonarr

## Radarr Setup (Movies)

### Installation

**Windows:**
1. Download from https://radarr.video/
2. Install with default settings
3. Access at `http://localhost:7878`

**Linux:**
```bash
# Download and install
curl -L -O https://github.com/Radarr/Radarr/releases/latest/download/Radarr.master.$(uname -m).tar.gz
sudo tar -xzf Radarr.*.tar.gz -C /opt/
sudo chown -R radarr:radarr /opt/Radarr

# Create service user
sudo useradd -d /var/lib/radarr -s /bin/bash radarr
sudo mkdir -p /var/lib/radarr
sudo chown radarr:radarr /var/lib/radarr

# Create systemd service
sudo tee /etc/systemd/system/radarr.service > /dev/null <<EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=radarr
Group=radarr
Type=simple
ExecStart=/opt/Radarr/Radarr -nobrowser -data=/var/lib/radarr
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable radarr
sudo systemctl start radarr
```

### Configuration

1. **Media Management**
   - Settings → Media Management
   - Root folders: Add `/data/media/movies`
   - Movie naming: Enable renaming
   - Standard movie format: `{Movie Title} ({Release Year})`
   - Movie folder format: `{Movie Title} ({Release Year})`

2. **Download Clients**
   - Settings → Download Clients
   - Add qBittorrent (same as Sonarr but with category: movies)

3. **Quality Profiles**
   - Settings → Profiles
   - Create "1080p Preferred" profile similar to Sonarr
   - Allowed qualities: HDTV-1080p, WEB-1080p, Bluray-1080p

4. **Custom Formats (Advanced)**
   - Settings → Custom Formats
   - Add formats to prefer certain releases (optional)

Source: https://wiki.servarr.com/radarr

## Lidarr Setup (Music)

### Installation

**Windows:**
1. Download from https://lidarr.audio/
2. Install with default settings
3. Access at `http://localhost:8686`

**Linux:**
```bash
# Download and install
curl -L -O https://github.com/Lidarr/Lidarr/releases/latest/download/Lidarr.master.$(uname -m).tar.gz
sudo tar -xzf Lidarr.*.tar.gz -C /opt/
sudo chown -R lidarr:lidarr /opt/Lidarr

# Create service user
sudo useradd -d /var/lib/lidarr -s /bin/bash lidarr
sudo mkdir -p /var/lib/lidarr
sudo chown lidarr:lidarr /var/lib/lidarr

# Create systemd service
sudo tee /etc/systemd/system/lidarr.service > /dev/null <<EOF
[Unit]
Description=Lidarr Daemon
After=syslog.target network.target

[Service]
User=lidarr
Group=lidarr
Type=simple
ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=/var/lib/lidarr
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable lidarr
sudo systemctl start lidarr
```

### Configuration

1. **Media Management**
   - Settings → Media Management
   - Root folders: Add `/data/media/music`
   - Track naming: Enable renaming
   - Standard track format: `{track:00} - {Track Title}`
   - Album folder format: `{Artist Name} - {Album Title} ({Release Year})`

2. **Download Clients**
   - Settings → Download Clients  
   - Add qBittorrent (category: music)

3. **Metadata Profiles**
   - Settings → Metadata Profiles
   - Standard profile typically works well
   - Adjust based on your quality preferences

4. **Quality Profiles**
   - Settings → Profiles
   - Create profile for preferred audio quality (FLAC, MP3-320, etc.)

Source: https://wiki.servarr.com/lidarr

## Directory Setup and Permissions

### Create Directory Structure

```bash
# Create directory structure
sudo mkdir -p /data/{media/{tv,movies,music},torrents/{complete,incomplete,watch}/{tv,movies,music}}

# Set ownership (replace 'username' with your user)
sudo chown -R username:username /data/media
sudo chown -R username:username /data/torrents

# Set permissions for applications
sudo usermod -a -G username sonarr
sudo usermod -a -G username radarr
sudo usermod -a -G username lidarr

# Set directory permissions
sudo chmod -R 775 /data/media
sudo chmod -R 775 /data/torrents
```

### qBittorrent Category Setup

1. **Categories in qBittorrent**
   - Options → Downloads
   - Category settings:
     - tv: `/data/torrents/complete/tv`
     - movies: `/data/torrents/complete/movies`
     - music: `/data/torrents/complete/music`

## Integration Configuration

### Post-Processing Scripts

Create scripts to move completed downloads to media directories:

**Linux Script Example:**
```bash
#!/bin/bash
# /opt/scripts/move-completed.sh

CATEGORY=$1
TORRENT_NAME=$2
CONTENT_DIR=$3

case $CATEGORY in
  "tv")
    rsync -av "$CONTENT_DIR/" /data/media/tv/ && rm -rf "$CONTENT_DIR"
    ;;
  "movies")
    rsync -av "$CONTENT_DIR/" /data/media/movies/ && rm -rf "$CONTENT_DIR"
    ;;
  "music")
    rsync -av "$CONTENT_DIR/" /data/media/music/ && rm -rf "$CONTENT_DIR"
    ;;
esac
```

### Application Integration

1. **Sonarr → qBittorrent**
   - Category: tv
   - Remote path: Map qBittorrent download path to Sonarr

2. **Radarr → qBittorrent**
   - Category: movies
   - Remote path: Map qBittorrent download path to Radarr

3. **Lidarr → qBittorrent**
   - Category: music
   - Remote path: Map qBittorrent download path to Lidarr

## Testing the Setup

### Verify Connections

1. **Test Download Clients**
   - Each *arr app → Settings → Download Clients → Test
   - Should show green checkmark

2. **Test File Access**
   - Add a test movie/show/album
   - Verify it appears in the respective application
   - Check that files are accessible by Jellyfin

### Common Integration Issues

1. **Permission Denied**
   ```bash
   # Fix ownership issues
   sudo chown -R sonarr:sonarr /data/media/tv
   sudo chown -R radarr:radarr /data/media/movies
   sudo chown -R lidarr:lidarr /data/media/music
   ```

2. **Path Mapping Issues**
   - Ensure all applications use same paths
   - Configure remote path mappings in download client settings

3. **Category Mismatch**
   - Verify qBittorrent categories match *arr application settings
   - Check category-specific save paths

## Monitoring and Logs

### Application Logs

**Sonarr:** `Settings → System → Logs`
**Radarr:** `Settings → System → Logs`
**Lidarr:** `Settings → System → Logs`

**Linux Log Locations:**
```bash
# View application logs
sudo journalctl -u sonarr -f
sudo journalctl -u radarr -f  
sudo journalctl -u lidarr -f
```

### Health Checks

All applications provide health monitoring:
- Dashboard shows warnings/errors
- Settings → System → Status shows system health
- Regular database maintenance tasks run automatically

## Next Steps

With the automation tools configured, proceed to set up indexers:

**Next Guide:** [Indexers and Trackers Setup](./04-indexers-setup.md)

This will connect your automation tools to torrent sites for content discovery and downloading.