# Jellyfin Media Server Docker Stack

A complete, configurable Docker deployment for automated media server with Jellyfin, Sonarr, Radarr, Lidarr, Prowlarr, and qBittorrent. Optimized for Proxmox VE environments with support for both LXC containers and traditional VMs.

## Proxmox Deployment Overview

### Recommended Deployment Methods

**Option 1: LXC Container (Recommended)**
- Deploy Docker stack within a Proxmox LXC container
- Better resource efficiency and management
- Hardware passthrough support (GPU acceleration)
- Integrated backup and snapshot capabilities

**Option 2: Virtual Machine**
- Traditional VM deployment with Docker
- Full OS isolation
- Better for complex networking scenarios

### Proxmox LXC Container Setup

1. **Create LXC Container**
   ```bash
   # Download Ubuntu template (if not already available)
   pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.xz
   
   # Create privileged container for Docker support
   pct create 101 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.xz \
     --hostname media-server \
     --cores 4 \
     --memory 4096 \
     --rootfs local-lvm:20 \
     --mp0 /mnt/media-storage,mp=/data,size=500G \
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \
     --onboot 1 \
     --features nesting=1
   
   # Start container
   pct start 101
   ```

2. **Container Configuration**
   ```bash
   # Enter container
   pct enter 101
   
   # Update system
   apt update && apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Install Docker Compose
   curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
   ```

### Hardware Acceleration Setup (Proxmox)

**Intel Quick Sync in LXC:**
```bash
# Add to LXC config (/etc/pve/lxc/101.conf)
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir

# Restart container
pct restart 101
```

**GPU Passthrough for NVIDIA:**
```bash
# Add GPU to LXC config
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 236:* rwm
lxc.mount.entry: /dev/nvidia0 dev/nvidia0 none bind,optional,create=file
lxc.mount.entry: /dev/nvidiactl dev/nvidiactl none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-modeset dev/nvidia-modeset none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm dev/nvidia-uvm none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm-tools dev/nvidia-uvm-tools none bind,optional,create=file
```

## Quick Start

1. **Prerequisites**
   ```bash
   # Install Docker and Docker Compose (if not using setup script)
   curl -fsSL https://get.docker.sh | sh
   sudo usermod -aG docker $USER
   newgrp docker
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Automated Setup (Recommended)**
   ```bash
   # Run the interactive setup script
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Manual Setup**
   ```bash
   # Create directory structure
   sudo mkdir -p /data/{config/{jellyfin,sonarr,radarr,lidarr,prowlarr,qbittorrent},media/{movies,tv,music},torrents/{completed,incomplete}}
   sudo chown -R $USER:$USER /data
   chmod -R 755 /data
   
   # Configure environment
   cp .env /data/.env
   nano /data/.env
   
   # Deploy stack
   docker compose --profile basic up -d
   ```

## Deployment Profiles

### Available Profiles

- **basic** - Core services (Jellyfin, Sonarr, Radarr, Lidarr, Prowlarr, qBittorrent)
- **vpn** - VPN-enabled qBittorrent for secure torrenting
- **optional** - Additional services (FlareSolverr, Jackett, Watchtower)  
- **dev** - Development tools (Portainer, Netdata)

### Profile Examples

```bash
# Minimal deployment
docker compose --profile basic up -d

# Basic with VPN
docker compose --profile basic --profile vpn up -d  

# Full production setup
docker compose --profile basic --profile optional up -d

# Development environment  
docker compose --profile basic --profile dev up -d

# Everything enabled
docker compose --profile basic --profile vpn --profile optional --profile dev up -d
```

## Configuration

### Required Configuration

Edit the environment file with your specific settings:

```bash
# Essential Settings
PUID=1000                              # User ID (get with: id $USER)
PGID=1000                              # Group ID
TZ=America/New_York                    # Your timezone
LAN_NETWORK=192.168.1.0/24            # Your LAN network range
DATA_ROOT=/data                        # Base data directory
JELLYFIN_PUBLISHED_URL=http://192.168.1.100:8096  # Server IP
```

### Proxmox-Specific Configuration

```bash
# Hardware Acceleration (Proxmox LXC)
JELLYFIN_INTEL_GPU=true               # Enable Intel Quick Sync
JELLYFIN_NVIDIA_GPU=false             # Enable NVIDIA GPU (requires passthrough)

# Container Resources
JELLYFIN_MEMORY_LIMIT=2g              # Jellyfin memory limit
QBITTORRENT_MEMORY_LIMIT=1g           # qBittorrent memory limit
ARR_MEMORY_LIMIT=512m                 # Memory limit per arr app

# Storage Configuration
TRANSCODING_STORAGE_TYPE=tmpfs        # Use tmpfs for transcoding (faster)
TRANSCODING_SIZE=4g                   # Transcoding cache size
```

### VPN Configuration

If using VPN profile, additional setup is required:

1. **Enable VPN in .env:**
   ```bash
   COMPOSE_PROFILES=basic,vpn
   VPN_ENABLED=true
   VPN_PROVIDER=generic  # or proton, pia
   ```

2. **Add WireGuard config:**
   ```bash
   # Create WireGuard config directory
   mkdir -p /data/config/qbittorrent-vpn/wireguard
   
   # Add your VPN config file
   # Place your wg0.conf file in: /data/config/qbittorrent-vpn/wireguard/wg0.conf
   ```

3. **Example WireGuard config:**
   ```ini
   [Interface]
   PrivateKey = your-private-key-here
   Address = 10.x.x.x/32
   DNS = 1.1.1.1
   
   [Peer]
   PublicKey = vpn-server-public-key
   AllowedIPs = 0.0.0.0/0
   Endpoint = vpn.example.com:51820
   ```

## Access URLs

After deployment, access services at:

- **Jellyfin:** http://[container-ip]:8096
- **Sonarr:** http://[container-ip]:8989  
- **Radarr:** http://[container-ip]:7878
- **Lidarr:** http://[container-ip]:8686
- **Prowlarr:** http://[container-ip]:9696
- **qBittorrent:** http://[container-ip]:8080
- **Jackett:** http://[container-ip]:9117 (if optional profile enabled)
- **Portainer:** http://[container-ip]:9000 (if dev profile enabled)

Note: Replace [container-ip] with your LXC container's IP address. In Proxmox, you can find this in the container's Summary tab or by running `pct exec 101 ip addr show eth0`.

## Hardware Acceleration

### Intel Quick Sync (Proxmox LXC)

For Intel CPUs with integrated graphics:

1. **Configure LXC container** (on Proxmox host):
   ```bash
   # Add to /etc/pve/lxc/[CTID].conf
   lxc.cgroup2.devices.allow: c 226:* rwm
   lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
   
   # Restart container
   pct restart [CTID]
   ```

2. **Verify inside container:**
   ```bash
   ls -la /dev/dri/
   # Should show render devices
   ```

3. **Enable in environment:**
   ```bash
   JELLYFIN_INTEL_GPU=true
   JELLYFIN_NVIDIA_GPU=false
   ```

### NVIDIA GPU (Proxmox LXC)

1. **Configure LXC container** (on Proxmox host):
   ```bash
   # Add to /etc/pve/lxc/[CTID].conf
   lxc.cgroup2.devices.allow: c 195:* rwm
   lxc.cgroup2.devices.allow: c 236:* rwm
   lxc.mount.entry: /dev/nvidia0 dev/nvidia0 none bind,optional,create=file
   lxc.mount.entry: /dev/nvidiactl dev/nvidiactl none bind,optional,create=file
   ```

2. **Install NVIDIA Container Toolkit** (inside container):
   ```bash
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/$distribution/amd64 /" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
   
   sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
   sudo systemctl restart docker
   ```

3. **Enable in environment:**
   ```bash
   JELLYFIN_NVIDIA_GPU=true
   JELLYFIN_INTEL_GPU=false
   ```

## Management Commands

### Basic Operations

```bash
# Start services
docker compose --profile basic up -d

# Stop services  
docker compose --profile basic down

# View logs
docker compose logs -f jellyfin
docker compose logs -f qbittorrent

# Update containers
docker compose pull
docker compose --profile basic up -d --force-recreate

# Restart single service
docker compose restart sonarr
```

### Maintenance

```bash
# Backup configuration
sudo tar -czf media-server-backup-$(date +%Y%m%d).tar.gz /data/config/

# Clean up unused images/containers
docker system prune -af

# Monitor resource usage
docker stats

# Check container health
docker compose ps
```

### Troubleshooting

```bash
# Check container logs
docker compose logs qbittorrent
docker compose logs --tail=50 -f sonarr

# Exec into container for debugging
docker compose exec jellyfin bash
docker compose exec qbittorrent-vpn bash

# Test VPN connectivity (if using VPN profile)
docker compose exec qbittorrent-vpn curl ifconfig.me

# Verify file permissions
ls -la /data/
```

## Initial Setup

### 1. Jellyfin Setup

1. Access Jellyfin at http://[container-ip]:8096
2. Complete setup wizard:
   - Create admin account
   - Add media libraries:
     - **Movies:** `/data/movies`
     - **TV Shows:** `/data/tvshows`  
     - **Music:** `/data/music`
3. Configure hardware transcoding (Dashboard > Playback)
4. Set transcoding path to `/transcode` (tmpfs for better performance)

### 2. qBittorrent Setup  

1. Access qBittorrent at http://[container-ip]:8080
2. Default login: `admin` / `adminadmin`
3. Change password immediately in Preferences
4. Configure download paths:
   - **Default Save Path:** `/data/torrents/incomplete`
   - **Completed Path:** `/data/torrents/completed`
5. Set up category-based organization:
   - Movies: `/data/torrents/movies`
   - TV: `/data/torrents/tv`
   - Music: `/data/torrents/music`

### 3. Automation Applications Setup

1. **Prowlarr** (http://[container-ip]:9696):
   - Add indexers (torrent trackers)
   - Configure Sonarr, Radarr, Lidarr applications
   - Add qBittorrent as download client

2. **Sonarr** (http://[container-ip]:8989):
   - Add root folder: `/tv`
   - Connect to Prowlarr for indexers
   - Add qBittorrent as download client
   - Configure quality and naming profiles

3. **Radarr** (http://[container-ip]:7878):
   - Add root folder: `/movies`
   - Connect to Prowlarr for indexers
   - Add qBittorrent as download client
   - Configure quality and naming profiles

4. **Lidarr** (http://[container-ip]:8686):
   - Add root folder: `/music`
   - Connect to Prowlarr for indexers
   - Add qBittorrent as download client
   - Configure quality and metadata profiles

## Security Considerations

### Network Security

- Services are isolated in Docker network
- Only necessary ports are exposed
- VPN traffic is properly contained

### File Security

- Containers run as specified user (PUID/PGID)  
- Read-only root filesystems where possible
- Proper file permissions and ownership

### VPN Security

- Only torrent client uses VPN
- Killswitch prevents IP leaks
- DNS leak protection enabled

## Advanced Configuration

### Custom Network Configuration

```yaml
networks:
  media-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
```

### Reverse Proxy Integration

For external access, integrate with reverse proxy:

```yaml
# Add to docker-compose.override.yml
services:
  jellyfin:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.yourdomain.com`)"
      - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
```

### Storage Optimization

```yaml
# Add SSD cache for transcoding
services:
  jellyfin:
    volumes:
      - /fast/ssd/path:/transcode  # Fast storage for transcoding
```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Fix ownership and permissions
   sudo chown -R $USER:$USER /data
   chmod -R 755 /data
   
   # Verify PUID/PGID match your user
   id $USER
   ```

2. **VPN Not Connecting**
   ```bash
   # Check WireGuard configuration
   docker compose exec qbittorrent-vpn cat /config/wireguard/wg0.conf
   
   # Monitor VPN connection logs
   docker compose logs -f qbittorrent-vpn | grep -i vpn
   
   # Test VPN connectivity
   docker compose exec qbittorrent-vpn curl ifconfig.me
   ```

3. **Hardware Acceleration Issues (Proxmox)**
   ```bash
   # Verify device availability inside container
   pct exec [CTID] ls -la /dev/dri/
   
   # Check LXC configuration
   cat /etc/pve/lxc/[CTID].conf | grep -E "(devices|mount)"
   
   # Restart container after configuration changes
   pct restart [CTID]
   ```

4. **Network Connectivity Issues**
   ```bash
   # Check container network
   docker network ls
   docker network inspect media-network
   
   # Verify port bindings
   docker compose ps
   
   # Test service connectivity from host
   curl -I http://[container-ip]:8096/health
   ```

5. **Storage and Performance**
   ```bash
   # Check disk usage
   df -h /data
   
   # Monitor I/O performance
   iostat -x 1
   
   # Check transcoding performance (if using tmpfs)
   mount | grep transcode
   ```

### Proxmox-Specific Troubleshooting

1. **Container Resource Limits**
   ```bash
   # Check container resources
   pct config [CTID]
   
   # Monitor resource usage
   pct exec [CTID] htop
   ```

2. **Hardware Passthrough Issues**
   ```bash
   # Verify host device availability
   ls -la /dev/dri/
   lspci | grep -i vga
   
   # Check container privileges
   pct config [CTID] | grep -i privileg
   ```

## Monitoring and Logs

### Health Checks

All services include health checks for monitoring:

```bash
# Check service health
docker compose ps

# Service-specific health
curl -f http://localhost:8096/health
```

### Log Management

Logs are automatically rotated:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

### Resource Monitoring

Enable dev profile for monitoring tools:

```bash
docker compose --profile basic --profile dev up -d

# Access Netdata at http://localhost:19999
# Access Portainer at http://localhost:9000
```

## Updates and Maintenance

### Automatic Updates

Enable Watchtower for automatic updates:

```bash
COMPOSE_PROFILES=basic,optional
```

### Manual Updates

```bash
# Update all containers
docker compose pull
docker compose --profile basic up -d

# Update specific container
docker compose pull jellyfin
docker compose up -d jellyfin
```

### Backup Strategy

```bash
#!/bin/bash
# Backup script
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/media-server"
mkdir -p "$BACKUP_DIR"

# Stop services
docker compose stop

# Backup configurations
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" /data/config/

# Backup database files
tar -czf "$BACKUP_DIR/databases-$DATE.tar.gz" \
  /data/config/*/databases/ \
  /data/config/*/logs/ 2>/dev/null

# Start services
docker compose --profile basic up -d

echo "Backup completed: $BACKUP_DIR"
```

## Support and Documentation

### Getting Help

- **Jellyfin:** https://jellyfin.org/docs
- **Sonarr:** https://wiki.servarr.com/sonarr
- **Radarr:** https://wiki.servarr.com/radarr  
- **Lidarr:** https://wiki.servarr.com/lidarr
- **Prowlarr:** https://wiki.servarr.com/prowlarr
- **Docker Compose:** https://docs.docker.com/compose/

### Community

- Discord servers for each application
- Reddit communities (/r/jellyfin, /r/sonarr, etc.)
- Official forums and GitHub issues

## Proxmox Management Integration

### Backup and Snapshots

```bash
# Create container snapshot
pct snapshot [CTID] snap-$(date +%Y%m%d)

# Backup container configuration
vzdump [CTID] --storage [backup-storage]

# Schedule automated backups in Proxmox
# Datacenter > Backup > Add (configure schedule)
```

### Resource Monitoring

```bash
# Monitor container resources
pct exec [CTID] docker stats

# Check container logs
pct exec [CTID] docker compose logs -f

# Monitor from Proxmox host
watch 'pct list | grep [CTID]'
```

### Container Migration

```bash
# Migrate to another Proxmox node (if clustered)
pct migrate [CTID] [target-node]

# Backup and restore to different system
vzdump [CTID]
pct restore [CTID] /backup/vzdump-lxc-[CTID]-*.tar.lzo
```

## Performance Optimization

### Storage Configuration

1. **Use local SSD for databases and transcoding**
   ```bash
   # Mount SSD storage in LXC
   pct set [CTID] -mp1 /mnt/ssd-storage,mp=/fast-storage
   
   # Configure transcoding on fast storage
   TRANSCODING_STORAGE_TYPE=bind
   TRANSCODING_PATH=/fast-storage/transcode
   ```

2. **Network storage for media**
   ```bash
   # Mount NFS/CIFS for media storage
   pct set [CTID] -mp2 /mnt/nas-media,mp=/data/media
   ```

### Memory and CPU Tuning

```bash
# Adjust container resources based on usage
pct set [CTID] -memory 8192 -cores 6

# Enable memory ballooning
pct set [CTID] -balloon 4096

# Set CPU limit
pct set [CTID] -cpulimit 4
```

## Security Considerations

### Network Security

- Container network isolation through Docker networks
- Proxmox firewall integration available
- VPN traffic properly contained within designated containers

### File System Security

- Containers run with specified user/group IDs (PUID/PGID)
- Read-only root filesystems where applicable
- Proper mount point permissions and ownership

### Access Control

- Services accessible only within defined network ranges
- Option to integrate with reverse proxy for external access
- Regular security updates through Watchtower (optional profile)

## License

This Docker deployment configuration is provided as-is for educational and personal use. Users are responsible for:
- Complying with local laws regarding content downloading and copyright
- Ensuring proper licensing for all media content
- Following terms of service for indexer and tracker sites
- Maintaining security and access controls appropriate for their environment