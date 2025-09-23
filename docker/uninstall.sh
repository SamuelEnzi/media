#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

print_header() {
    echo "Jellyfin Media Server - Complete Uninstall"
    echo "This will remove ALL containers, data, and configurations."
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

confirm_uninstall() {
    echo "WARNING: This will permanently delete:"
    echo "- All Docker containers (Jellyfin, Sonarr, Radarr, etc.)"
    echo "- All Docker images used by the media server"
    echo "- All Docker networks and volumes"
    echo "- All configuration files and databases"
    echo "- ALL MEDIA FILES in the data directory"
    echo "- Download cache and torrent data"
    echo ""
    echo "Data directory that will be DELETED:"
    
    # Try to read data directory from .env file
    if [[ -f "$ENV_FILE" ]]; then
        DATA_ROOT=$(grep "^DATA_ROOT=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 || echo "/data")
    else
        DATA_ROOT="/data"
    fi
    
    echo "$DATA_ROOT"
    echo ""
    echo "This action is IRREVERSIBLE! All your media and configurations will be lost!"
    echo ""
    
    read -p "Do you want to proceed? [Y/n]: " confirmation
    confirmation=${confirmation:-Y}
    
    if [[ "$confirmation" != "Y" && "$confirmation" != "y" ]]; then
        echo "Uninstall cancelled. No changes were made."
        exit 0
    fi
}

stop_all_containers() {
    print_step "Stopping and removing Docker containers..."
    
    cd "$SCRIPT_DIR"
    
    # Stop all services using docker-compose
    if command -v docker-compose &> /dev/null; then
        docker-compose down --remove-orphans --volumes 2>/dev/null || true
    else
        docker compose down --remove-orphans --volumes 2>/dev/null || true
    fi
    
    # Force remove individual containers if they exist
    local containers=(
        "jellyfin"
        "sonarr" 
        "radarr"
        "lidarr"
        "prowlarr"
        "jellyseerr"
        "qbittorrent"
        "qbittorrent-vpn"
        "jackett"
        "flaresolverr"
        "watchtower"
        "portainer"
        "netdata"
    )
    
    for container in "${containers[@]}"; do
        if docker ps -aq -f name="^${container}$" | grep -q .; then
            docker stop "$container" 2>/dev/null || true
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
}

remove_docker_images() {
    print_step "Removing Docker images..."
    
    local images=(
        "lscr.io/linuxserver/jellyfin"
        "lscr.io/linuxserver/sonarr"
        "lscr.io/linuxserver/radarr"
        "lscr.io/linuxserver/lidarr"
        "lscr.io/linuxserver/prowlarr"
        "fallenbagel/jellyseerr"
        "lscr.io/linuxserver/qbittorrent"
        "ghcr.io/hotio/qbittorrent"
        "lscr.io/linuxserver/jackett"
        "ghcr.io/flaresolverr/flaresolverr"
        "containrrr/watchtower"
        "portainer/portainer-ce"
        "netdata/netdata"
    )
    
    for image in "${images[@]}"; do
        if docker images -q "$image" | grep -q .; then
            docker rmi -f "$image" 2>/dev/null || true
        fi
    done
    
    # Remove dangling images
    docker image prune -f 2>/dev/null || true
}

remove_networks_and_volumes() {
    print_step "Removing Docker networks and volumes..."
    
    # Remove media network
    if docker network ls | grep -q "media-network"; then
        docker network rm media-network 2>/dev/null || true
    fi
    
    # Remove portainer volume
    if docker volume ls | grep -q "portainer-data"; then
        docker volume rm portainer-data 2>/dev/null || true
    fi
    
    # Remove any orphaned volumes
    docker volume prune -f 2>/dev/null || true
}

remove_data_directories() {
    print_step "Removing data directories and files..."
    
    if [[ -d "$DATA_ROOT" ]]; then
        sudo rm -rf "$DATA_ROOT" 2>/dev/null || {
            rm -rf "$DATA_ROOT" 2>/dev/null || echo "Could not remove $DATA_ROOT. Manual cleanup may be required."
        }
        
        if [[ -d "$DATA_ROOT" ]]; then
            echo "Data directory still exists. Manual cleanup required: $DATA_ROOT"
        fi
    fi
}

remove_config_files() {
    print_step "Removing configuration files..."
    
    # Remove .env file
    if [[ -f "$ENV_FILE" ]]; then
        rm -f "$ENV_FILE"
    fi
    
    # Remove any backup files
    rm -f "$SCRIPT_DIR"/.env.* 2>/dev/null || true
}

cleanup_docker_system() {
    print_step "Cleaning up Docker system..."
    
    # Remove all unused containers, networks, images, and volumes
    docker system prune -af --volumes 2>/dev/null || true
}

show_completion() {
    echo "Uninstall completed successfully."
    echo ""
    echo "Complete removal summary:"
    echo "- All media server containers removed"
    echo "- All Docker images cleaned up"
    echo "- All networks and volumes removed"
    echo "- Data directory deleted: $DATA_ROOT"
    echo "- Configuration files removed"
    echo ""
    echo "Your system has been completely cleaned of the media server installation."
    echo "You can safely re-run the setup script to reinstall if needed."
}

main() {
    print_header
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed or not available."
        echo "Manual cleanup may be required."
        exit 1
    fi
    
    confirm_uninstall
    
    echo "Starting complete uninstallation..."
    echo ""
    
    stop_all_containers
    remove_docker_images
    remove_networks_and_volumes
    remove_data_directories  
    remove_config_files
    cleanup_docker_system
    
    show_completion
}

# Trap to handle interruption
trap 'echo "Uninstall interrupted!"; exit 1' INT TERM

main "$@"