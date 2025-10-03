# Media Server

Complete Jellyfin media server with automated downloading (Sonarr/Radarr/Lidarr) and secure VPN torrenting.

## Preparation

Install Docker and add user to docker group:
```bash
sudo usermod -aG docker $USER && newgrp docker
```

Collect this information:
- User ID: `id -u`
- Group ID: `id -g`  
- Timezone (e.g., America/New_York)
- Server IP address
- Mullvad Wireguard configuration

## VPN Configuration

For secure torrenting with Mullvad VPN:

1. **Get Mullvad Config:**
   - Visit [mullvad.net/account/wireguard-config](https://mullvad.net/account/wireguard-config)
   - Generate a new key pair if needed
   - Copy your private key and IP address

2. **Required Information:**
   - Wireguard private key
   - Wireguard addresses (e.g., 10.64.222.21/32)
   - Preferred countries/cities (optional)

## Volume Setup

Create storage directories:
```bash
sudo mkdir -p /data/{config,media/{movies,tv,music},torrents}
sudo chown -R $(id -u):$(id -g) /data
```

Mount points:
- `/data/config` - Application configurations
- `/data/media` - Media files (movies/tv/music)
- `/data/torrents` - Download cache
- `/dev/dri` - Hardware acceleration (Intel GPU)

## Installation

Run the simplified setup script:
```bash
bash ./setup.sh
```

Or deploy manually:
```bash
docker compose up -d
```

## Internet Ports

Forward these ports (TCP):

**Required:**
- 8096 - Jellyfin media server

**Optional (management):**
- 8989 - Sonarr
- 7878 - Radarr  
- 8686 - Lidarr
- 9696 - Prowlarr
- 5055 - Jellyseerr
