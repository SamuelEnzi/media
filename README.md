# Media Server

Jellyfin media server with automated downloading (Sonarr/Radarr/Lidarr) and VPN support.

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
- VPN WireGuard config (optional)

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

Run interactive setup:
```bash
cd docker && ./setup.sh
```

Or deploy manually:
```bash
docker compose --profile basic up -d
```

With VPN:
```bash
docker compose --profile basic --profile vpn up -d
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
