#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

DEFAULT_DATA_ROOT="/data"
DEFAULT_USER_ID="$(id -u)"
DEFAULT_GROUP_ID="$(id -g)"
DEFAULT_TIMEZONE="$(timedatectl show --property=Timezone --value 2>/dev/null || echo "America/New_York")"

print_header() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "  Jellyfin Media Server Docker Setup"
    echo "  Complete automated media server deployment"
    echo "================================================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        print_info "Please run as a regular user who is in the docker group."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed."
        print_info "Please install Docker first: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed."
        print_info "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running or accessible."
        print_info "Make sure Docker is running and your user is in the docker group:"
        print_info "sudo usermod -aG docker \$USER && newgrp docker"
        exit 1
    fi
    
    print_info "✓ All prerequisites met"
}

get_user_input() {
    print_step "Gathering configuration information..."
    
    echo -n "Enter data directory path [$DEFAULT_DATA_ROOT]: "
    read -r DATA_ROOT
    DATA_ROOT=${DATA_ROOT:-$DEFAULT_DATA_ROOT}
    
    echo -n "Enter PUID [$DEFAULT_USER_ID]: "
    read -r PUID
    PUID=${PUID:-$DEFAULT_USER_ID}
    
    echo -n "Enter PGID [$DEFAULT_GROUP_ID]: "
    read -r PGID  
    PGID=${PGID:-$DEFAULT_GROUP_ID}
    
    echo -n "Enter timezone [$DEFAULT_TIMEZONE]: "
    read -r TIMEZONE
    TIMEZONE=${TIMEZONE:-$DEFAULT_TIMEZONE}
    
    DEFAULT_NETWORK=$(ip route | grep -E "192\.168\.|10\.|172\." | head -1 | awk '{print $1}' | head -1 || echo "192.168.1.0/24")
    echo -n "Enter LAN network [$DEFAULT_NETWORK]: "
    read -r LAN_NETWORK
    LAN_NETWORK=${LAN_NETWORK:-$DEFAULT_NETWORK}
    
    DEFAULT_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    echo -n "Enter server IP for Jellyfin [$DEFAULT_IP]: "
    read -r SERVER_IP
    SERVER_IP=${SERVER_IP:-$DEFAULT_IP}
    
    echo ""
    echo "Select deployment profile:"
    echo "1) Basic (Core services only)"
    echo "2) Basic + VPN (Secure torrenting)"  
    echo "3) Basic + Optional (Additional services)"
    echo "4) Full (Basic + VPN + Optional)"
    echo -n "Enter choice [1-4]: "
    read -r PROFILE_CHOICE
    
    case $PROFILE_CHOICE in
        1) COMPOSE_PROFILES="basic" ;;
        2) COMPOSE_PROFILES="basic,vpn" ;;
        3) COMPOSE_PROFILES="basic,optional" ;;
        4) COMPOSE_PROFILES="basic,vpn,optional" ;;
        *) COMPOSE_PROFILES="basic" ;;
    esac
    
    if [[ $COMPOSE_PROFILES == *"vpn"* ]]; then
        echo ""
        print_info "VPN profile selected. Additional VPN configuration required."
        echo -n "VPN provider (torguard/proton/pia/generic) [torguard]: "
        read -r VPN_PROVIDER
        VPN_PROVIDER=${VPN_PROVIDER:-torguard}
        
        VPN_ENABLED="true"
    else
        VPN_ENABLED="false"
        VPN_PROVIDER="torguard"
    fi
}

create_directories() {
    print_step "Creating directory structure..."
    sudo mkdir -p "$DATA_ROOT"/{config/{jellyfin,sonarr,radarr,lidarr,prowlarr,qbittorrent,qbittorrent-vpn,jackett},media/{movies,tv,music},torrents/{movies,tv,music,completed,incomplete}}
    sudo chown -R "$PUID:$PGID" "$DATA_ROOT"
    chmod -R 755 "$DATA_ROOT"
    print_info "✓ Directory structure created: $DATA_ROOT"
}

generate_env_file() {
    print_step "Generating environment configuration..."
    
    cat > "$ENV_FILE" << EOF
# =============================================================================
# Media Server Docker Configuration - Generated $(date)
# =============================================================================

# Basic Configuration
PUID=$PUID
PGID=$PGID
TZ=$TIMEZONE
DATA_ROOT=$DATA_ROOT
LAN_NETWORK=$LAN_NETWORK
JELLYFIN_PUBLISHED_URL=http://$SERVER_IP:8096

# Deployment Profile
COMPOSE_PROFILES=$COMPOSE_PROFILES

# VPN Configuration
VPN_ENABLED=$VPN_ENABLED
VPN_PROVIDER=$VPN_PROVIDER
VPN_CONF=wg0
VPN_AUTO_PORT_FORWARD=true
VPN_FIREWALL_TYPE=auto
VPN_HEALTHCHECK_ENABLED=true
VPN_NAMESERVERS=1.1.1.1,8.8.8.8

# Port Configuration (default values)
JELLYFIN_HTTP_PORT=8096
JELLYFIN_HTTPS_PORT=8920
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
PROWLARR_PORT=9696
QBITTORRENT_PORT=8080
QBITTORRENT_TORRENT_PORT=6881
JACKETT_PORT=9117
FLARESOLVERR_PORT=8191

# Hardware Acceleration
JELLYFIN_INTEL_GPU=true
JELLYFIN_NVIDIA_GPU=false
JELLYFIN_AMD_GPU=false

# Advanced Settings
RESTART_POLICY=unless-stopped
NETWORK_NAME=media-network
LOG_DRIVER=json-file
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3
EOF

    print_info "✓ Environment file created: $ENV_FILE"
}

setup_vpn_config() {
    if [[ $VPN_ENABLED == "true" ]]; then
        print_step "Setting up VPN configuration..."
        
        VPN_CONFIG_DIR="$DATA_ROOT/config/qbittorrent-vpn/wireguard"
        mkdir -p "$VPN_CONFIG_DIR"
        
        print_warning "TorGuard WireGuard configuration required!"
        print_info "Please place your TorGuard WireGuard configuration file at:"
        print_info "  $VPN_CONFIG_DIR/wg0.conf"
        echo ""
        print_info "Get your TorGuard WireGuard config:"
        echo "  1. Login to https://torguard.net/config-generator"
        echo "  2. Select 'WireGuard' protocol"
        echo "  3. Choose your server location"
        echo "  4. Download the .conf file"
        echo "  5. Copy it to: $VPN_CONFIG_DIR/wg0.conf"
        echo ""
        print_info "TorGuard supports port forwarding for optimal BitTorrent performance"
        echo ""
        
        read -p "Press Enter when you have placed the TorGuard WireGuard config file..."
        
        if [[ ! -f "$VPN_CONFIG_DIR/wg0.conf" ]]; then
            print_warning "TorGuard WireGuard config not found. You can add it later."
        else
            print_info "✓ VPN configuration found"
        fi
    fi
}

deploy_services() {
    print_step "Deploying media server services..."
    
    cd "$SCRIPT_DIR"
    
    print_info "Pulling Docker images..."
    if command -v docker-compose &> /dev/null; then
        docker-compose pull
    else
        docker compose pull
    fi
    
    print_info "Starting services with profile: $COMPOSE_PROFILES"
    if command -v docker-compose &> /dev/null; then
        COMPOSE_PROFILES="$COMPOSE_PROFILES" docker-compose up -d
    else
        COMPOSE_PROFILES="$COMPOSE_PROFILES" docker compose up -d
    fi
    
    print_info "✓ Services deployed successfully"
}

show_access_info() {
    print_step "Service access information..."
    
    echo ""
    echo -e "${GREEN}Services are now running! Access URLs:${NC}"
    echo "┌─────────────────────────────────────────────────┐"
    echo "│  Service     │  URL                           │"
    echo "├─────────────────────────────────────────────────┤"
    echo "│  Jellyfin    │  http://$SERVER_IP:8096        │"
    echo "│  Sonarr      │  http://$SERVER_IP:8989        │"
    echo "│  Radarr      │  http://$SERVER_IP:7878        │"
    echo "│  Lidarr      │  http://$SERVER_IP:8686        │"
    echo "│  Prowlarr    │  http://$SERVER_IP:9696        │"
    echo "│  qBittorrent │  http://$SERVER_IP:8080        │"
    
    if [[ $COMPOSE_PROFILES == *"optional"* ]]; then
        echo "│  Jackett     │  http://$SERVER_IP:9117        │"
        echo "│  FlareSolverr│  http://$SERVER_IP:8191        │"
    fi
    
    echo "└─────────────────────────────────────────────────┘"
    echo ""
    
    print_info "Default qBittorrent credentials: admin / adminadmin"
    print_warning "Please change the qBittorrent password immediately!"
    
    if [[ $VPN_ENABLED == "true" ]]; then
        echo ""
        print_warning "VPN is enabled for torrenting."
        print_info "Verify VPN connectivity: docker compose exec qbittorrent-vpn curl ifconfig.me"
    fi
    
    echo ""
    print_info "Next steps:"
    echo "  1. Setup Jellyfin at http://$SERVER_IP:8096"
    echo "  2. Configure qBittorrent and change password"
    echo "  3. Setup indexers in Prowlarr"
    echo "  4. Configure Sonarr, Radarr, and Lidarr"
    echo ""
    print_info "For detailed setup instructions, see README.md"
}

show_management_commands() {
    echo ""
    echo -e "${BLUE}Management Commands:${NC}"
    echo "  View logs:        docker compose logs -f [service]"
    echo "  Stop services:    docker compose down"
    echo "  Restart service:  docker compose restart [service]"
    echo "  Update services:  docker compose pull && docker compose up -d"
    echo "  Check status:     docker compose ps"
    echo ""
}

main() {
    print_header
    
    check_prerequisites
    get_user_input
    create_directories
    generate_env_file
    setup_vpn_config
    deploy_services
    
    print_step "Setup completed successfully!"
    
    show_access_info
    show_management_commands
    
    print_info "Setup complete! Your media server is ready to use."
}

trap 'echo -e "\n${RED}Setup interrupted!${NC}"; exit 1' INT TERM
main "$@"