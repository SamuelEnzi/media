# Complete Media Server Setup Guide

## Overview

This guide provides step-by-step instructions for setting up a complete automated media server system using Jellyfin as the media server and various automation tools for downloading movies, TV shows, and music via torrents.

## System Architecture

The complete media server consists of these components:

**Core Components:**
- **Jellyfin** - Media server for streaming content (movies, TV shows, music)
- **Sonarr** - TV show collection manager and automation
- **Radarr** - Movie collection manager and automation  
- **Lidarr** - Music collection manager and automation
- **qBittorrent** - Torrent client for downloading content
- **Prowlarr/Jackett** - Indexer manager for torrent sites

**Optional Security Components:**
- **VPN** - For secure torrenting (recommended in certain jurisdictions)
- **Reverse Proxy** - For secure remote access

## Hardware Requirements

Based on official Jellyfin documentation, minimum requirements are:

**For servers with integrated graphics:**
- CPU: Intel Core i5-11400, Intel Pentium Gold G7400, Intel N100, or Apple M series
- RAM: 8GB system RAM (4GB sufficient for Linux without GUI)
- GPU: Intel UHD 710, Apple M series or newer
- Storage: 100GB SSD for OS and applications
- Network: Gigabit Ethernet (Wi-Fi not recommended)

**For servers with dedicated graphics:**
- CPU: Intel Core i5-2300, AMD FX-8100 or better
- RAM: 8GB (4GB for Linux headless)
- GPU: Intel Arc A series, Nvidia GTX16/RTX20 series or newer
- Storage: 100GB SSD for system, additional storage for media
- Network: Gigabit Ethernet

**Avoid:**
- Intel Atom CPUs (J/M/N/Y series up to 11th gen)
- AMD graphics cards (poor encoder quality)
- Most single board computers including Raspberry Pi
- Prebuilt NAS devices

Sources: 
- https://jellyfin.org/docs/general/administration/hardware-selection

## Directory Structure

Recommended directory structure for the media server:

```
/data/
├── media/
│   ├── movies/
│   ├── tv/
│   └── music/
├── torrents/
│   ├── movies/
│   ├── tv/
│   └── music/
└── config/
    ├── jellyfin/
    ├── sonarr/
    ├── radarr/
    ├── lidarr/
    ├── qbittorrent/
    └── prowlarr/
```

## Setup Guides

Follow these guides in order for a complete setup:

1. **[Jellyfin Media Server Setup](./02-jellyfin-setup.md)**
   - Installation and basic configuration
   - Hardware acceleration setup
   - Library organization

2. **[Automation Tools Setup](./03-automation-tools-setup.md)**
   - Sonarr (TV shows)
   - Radarr (movies)
   - Lidarr (music)
   - qBittorrent configuration

3. **[Indexers and Trackers Setup](./04-indexers-setup.md)**
   - Prowlarr configuration (recommended)
   - Jackett alternative setup
   - Connecting to automation tools

4. **[VPN and Security Setup](./05-vpn-security-setup.md)**
   - VPN configuration for torrenting
   - Binding torrent client to VPN
   - Security best practices

5. **[Docker Deployment (Optional)](./06-docker-deployment.md)**
   - Complete Docker Compose setup
   - Container management
   - Updates and maintenance

## Key Integration Points

**Download Flow:**
1. Sonarr/Radarr/Lidarr monitor for new releases
2. Search indexers via Prowlarr/Jackett
3. Send torrent to qBittorrent
4. Downloaded files moved to media directories
5. Jellyfin automatically detects new content

**Network Binding:**
- Only torrent client should use VPN
- Media server applications should have direct internet access
- Bind torrent client to VPN interface to prevent IP leaks

## Important Security Notes

- Use VPN only when legally required or for privacy
- Most countries only need secure DNS (1.1.1.1, 8.8.8.8)
- VPNs often cause more problems than they solve
- Private trackers typically ban VPN usage
- Only bind torrent client to VPN, not other applications

Sources:
- https://wiki.servarr.com/vpn

## Getting Help

If you encounter issues:

- **Jellyfin:** https://jellyfin.org/docs
- **Sonarr:** https://wiki.servarr.com/sonarr  
- **Radarr:** https://wiki.servarr.com/radarr
- **Lidarr:** https://wiki.servarr.com/lidarr
- **Prowlarr:** https://wiki.servarr.com/prowlarr
- **qBittorrent:** https://github.com/qbittorrent/qBittorrent/wiki

**Community Support:**
- Discord servers for each application
- Reddit communities
- Official forums

## Legal Disclaimer

This guide is for educational purposes. Users are responsible for complying with local laws regarding content downloading and copyright. Only download content you have the legal right to possess.