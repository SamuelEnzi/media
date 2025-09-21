# Docker Deployment Guide

## Overview

This guide covers deploying the complete media server stack using Docker containers. Docker provides easier management, updates, and isolation compared to native installations.

## Prerequisites

### Install Docker and Docker Compose

**Linux (Ubuntu/Debian):**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**Windows:**
1. Install Docker Desktop from https://www.docker.com/products/docker-desktop
2. Enable WSL 2 integration if using Windows 10/11
3. Docker Compose is included with Docker Desktop

**macOS:**
1. Install Docker Desktop from https://www.docker.com/products/docker-desktop
2. Docker Compose is included with Docker Desktop

Source: https://docs.docker.com/engine/install/

## Directory Structure

Create the directory structure for Docker deployment:

```bash
# Create directory structure
sudo mkdir -p /data/{config/{jellyfin,sonarr,radarr,lidarr,prowlarr,qbittorrent},media/{movies,tv,music},torrents/{movies,tv,music}}

# Set ownership (replace 'username' with your user)
sudo chown -R $USER:$USER /data

# Set permissions
chmod -R 755 /data
```

## Complete Docker Compose Configuration

Create a comprehensive `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  # Jellyfin Media Server
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - JELLYFIN_PublishedServerUrl=http://192.168.1.100:8096
    volumes:
      - /data/config/jellyfin:/config
      - /data/media/tv:/data/tvshows
      - /data/media/movies:/data/movies
      - /data/media/music:/data/music
    ports:
      - 8096:8096
      - 8920:8920 # HTTPS (optional)
      - 7359:7359/udp # Service discovery
      - 1900:1900/udp # DLNA
    devices:
      - /dev/dri:/dev/dri # Hardware acceleration (Intel/AMD)
    restart: unless-stopped
    networks:
      - media-network

  # qBittorrent Torrent Client
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - WEBUI_PORT=8080
    volumes:
      - /data/config/qbittorrent:/config
      - /data/torrents:/data/torrents
    ports:
      - 8080:8080 # Web UI
      - 6881:6881 # Torrent port
      - 6881:6881/udp
    restart: unless-stopped
    networks:
      - media-network

  # Sonarr - TV Shows
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /data/config/sonarr:/config
      - /data/media/tv:/tv
      - /data/torrents:/data/torrents
    ports:
      - 8989:8989
    restart: unless-stopped
    networks:
      - media-network

  # Radarr - Movies
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /data/config/radarr:/config
      - /data/media/movies:/movies
      - /data/torrents:/data/torrents
    ports:
      - 7878:7878
    restart: unless-stopped
    networks:
      - media-network

  # Lidarr - Music
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /data/config/lidarr:/config
      - /data/media/music:/music
      - /data/torrents:/data/torrents
    ports:
      - 8686:8686
    restart: unless-stopped
    networks:
      - media-network

  # Prowlarr - Indexer Manager
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /data/config/prowlarr:/config
    ports:
      - 9696:9696
    restart: unless-stopped
    networks:
      - media-network

  # Optional: FlareSolverr for Cloudflare-protected sites
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    environment:
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=none
      - TZ=America/New_York
    ports:
      - 8191:8191
    restart: unless-stopped
    networks:
      - media-network

networks:
  media-network:
    driver: bridge

# Optional: Define volumes for easier backup
volumes:
  jellyfin-config:
  sonarr-config:
  radarr-config:
  lidarr-config:
  prowlarr-config:
  qbittorrent-config:
```

Save this as `/data/docker-compose.yml`

## Environment Configuration

### User and Group IDs

Find your user and group IDs:
```bash
id $USER
# Output: uid=1000(username) gid=1000(username) groups=...
```

Update the `PUID` and `PGID` values in the compose file to match your user.

### Timezone

Set the appropriate timezone:
```bash
# List available timezones
timedatectl list-timezones | grep -i america

# Update TZ values in compose file
# Examples: America/New_York, Europe/London, Asia/Tokyo
```

### Network Configuration

Update the `JELLYFIN_PublishedServerUrl` with your server's actual IP address:
```bash
# Find your server IP
ip route get 1.1.1.1 | awk '{print $7}' | head -1
```

## VPN Integration (Optional)

For secure torrenting, you can use a VPN-enabled qBittorrent container:

### Hotio qBittorrent with VPN

Replace the qBittorrent service in your compose file:

```yaml
  qbittorrent:
    image: hotio/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - VPN_ENABLED=true
      - VPN_PROVIDER=custom
      - VPN_CONFIG_FILE=/config/wireguard/wg0.conf
    volumes:
      - /data/config/qbittorrent:/config
      - /data/torrents:/data/torrents
      - /data/vpn/wireguard.conf:/config/wireguard/wg0.conf:ro
    ports:
      - 8080:8080
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
    networks:
      - media-network
```

### VPN Configuration File

Create WireGuard configuration file:
```bash
# Create VPN config directory
mkdir -p /data/vpn

# Example WireGuard config (/data/vpn/wireguard.conf)
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.x.x.x/32
DNS = 1.1.1.1

[Peer]
PublicKey = VPN_SERVER_PUBLIC_KEY
Endpoint = vpn.server.com:51820
AllowedIPs = 0.0.0.0/0
```

Source: https://hotio.dev/containers/qbittorrent/

## Deployment and Startup

### Initial Deployment

```bash
# Navigate to directory containing docker-compose.yml
cd /data

# Pull all images
docker-compose pull

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Verify Services

Check that all services are accessible:
- Jellyfin: http://localhost:8096
- qBittorrent: http://localhost:8080
- Sonarr: http://localhost:8989
- Radarr: http://localhost:7878
- Lidarr: http://localhost:8686
- Prowlarr: http://localhost:9696

## Initial Configuration

### qBittorrent Setup

1. **Access Web UI:** http://localhost:8080
2. **Default Login:** admin/adminadmin
3. **Change Password:** Options → Web UI → Authentication
4. **Configure Categories:**
   ```
   tv: /data/torrents/tv
   movies: /data/torrents/movies  
   music: /data/torrents/music
   ```

### Application Configuration

Follow the same configuration steps from previous guides:

1. **Sonarr Configuration:**
   - Root folder: `/tv`
   - Download client: qBittorrent (host: qbittorrent, port: 8080)

2. **Radarr Configuration:**
   - Root folder: `/movies`
   - Download client: qBittorrent (host: qbittorrent, port: 8080)

3. **Lidarr Configuration:**
   - Root folder: `/music`
   - Download client: qBittorrent (host: qbittorrent, port: 8080)

4. **Prowlarr Configuration:**
   - Applications: Add Sonarr, Radarr, Lidarr using container names as hosts

## Hardware Acceleration

### Intel Quick Sync

For Intel hardware acceleration in Jellyfin:

```yaml
  jellyfin:
    # ... other config
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - "109" # render group ID
```

Check render group ID:
```bash
getent group render
# render:x:109:
```

### NVIDIA GPU

For NVIDIA hardware acceleration:

```yaml
  jellyfin:
    # ... other config
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
```

Requires nvidia-container-toolkit installation:
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

Source: https://github.com/NVIDIA/nvidia-container-toolkit

## Management and Maintenance

### Container Management

**Basic Commands:**
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart jellyfin

# View logs
docker-compose logs jellyfin -f

# Execute commands in container
docker exec -it jellyfin bash
```

### Updates

**Update All Containers:**
```bash
# Stop services
docker-compose down

# Pull latest images
docker-compose pull

# Remove old images
docker image prune

# Start services
docker-compose up -d
```

**Update Single Container:**
```bash
# Stop specific service
docker-compose stop jellyfin

# Pull latest image
docker-compose pull jellyfin

# Start service
docker-compose up -d jellyfin
```

### Backups

**Backup Configuration:**
```bash
#!/bin/bash
# /opt/scripts/backup-media-stack.sh

BACKUP_DIR="/backup/media-stack/$(date +%Y%m%d)"
CONFIG_DIR="/data/config"

mkdir -p "$BACKUP_DIR"

# Stop services for consistent backup
cd /data && docker-compose stop

# Backup configurations
tar -czf "$BACKUP_DIR/config-backup.tar.gz" -C /data config/

# Backup compose file
cp /data/docker-compose.yml "$BACKUP_DIR/"

# Start services
cd /data && docker-compose start

# Remove old backups (keep 30 days)
find /backup/media-stack/ -type d -mtime +30 -exec rm -rf {} +
```

### Monitoring

**Health Check Script:**
```bash
#!/bin/bash
# /opt/scripts/media-stack-health.sh

SERVICES="jellyfin qbittorrent sonarr radarr lidarr prowlarr"

for service in $SERVICES; do
    if docker-compose ps | grep -q "$service.*Up"; then
        echo "✓ $service is running"
    else
        echo "✗ $service is not running"
        # Optional: restart service
        docker-compose restart $service
    fi
done
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   ```bash
   # Fix ownership
   sudo chown -R 1000:1000 /data/config
   sudo chown -R 1000:1000 /data/media
   sudo chown -R 1000:1000 /data/torrents
   ```

2. **Cannot Connect Between Containers**
   ```bash
   # Check network connectivity
   docker exec jellyfin ping sonarr
   
   # Verify network configuration
   docker network inspect data_media-network
   ```

3. **Port Conflicts**
   ```bash
   # Check port usage
   netstat -tlnp | grep :8096
   
   # Modify ports in docker-compose.yml if needed
   ```

4. **Hardware Acceleration Not Working**
   ```bash
   # Check device access
   docker exec jellyfin ls -la /dev/dri/
   
   # Verify group membership
   docker exec jellyfin id
   ```

### Log Analysis

**View Container Logs:**
```bash
# All services
docker-compose logs

# Specific service with timestamps
docker-compose logs -t jellyfin

# Follow logs in real-time
docker-compose logs -f sonarr

# Last 100 lines
docker-compose logs --tail=100 qbittorrent
```

### Performance Optimization

1. **Resource Limits**
   ```yaml
   services:
     jellyfin:
       # ... other config
       deploy:
         resources:
           limits:
             memory: 4G
           reservations:
             memory: 2G
   ```

2. **Restart Policies**
   ```yaml
   # Ensure services auto-restart
   restart: unless-stopped
   ```

3. **Network Optimization**
   ```yaml
   networks:
     media-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.20.0.0/16
   ```

## Advanced Configuration

### Reverse Proxy Setup

Using Traefik for SSL and domain access:

```yaml
  traefik:
    image: traefik:v3.0
    container_name: traefik
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
      - --certificatesresolvers.letsencrypt.acme.email=your@email.com
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - media-network

  jellyfin:
    # ... existing config
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.yourdomain.com`)"
      - "traefik.http.routers.jellyfin.entrypoints=websecure"
      - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
      - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
```

### Resource Monitoring

Add monitoring stack:

```yaml
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - media-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3000:3000"
    networks:
      - media-network
```

## Conclusion

Docker deployment provides:
- Easy management and updates
- Consistent environments
- Better isolation and security
- Simplified backup and restore
- Scalability options

The containerized setup is ideal for users who want a maintainable, reproducible media server deployment.

**Proceed to the final step:** Review all documentation to ensure accuracy and completeness.